package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	machinesCommandID = "tailscale-machines"
	machinesLoader    = "devices"
	refreshMachinesID = "refresh-devices"
	hostnameUnavailID = "hostname-unavailable"
	tailscaleCacheKey = "tailscale-binary"
	statusTimeoutMs   = 12000
	statusOutputLimit = 4000000
	refreshIntervalMs = 15000
	binaryCacheTTL    = 24 * time.Hour
	subtitleSeparator = " · "
)

var tailscaleCandidates = []string{
	"tailscale",
	"/opt/homebrew/bin/tailscale",
	"/usr/local/bin/tailscale",
	"/Applications/Tailscale.app/Contents/MacOS/Tailscale",
	"/usr/bin/tailscale",
}

type tailscaleDevice struct {
	ID           string   `json:"ID"`
	PublicKey    string   `json:"PublicKey"`
	HostName     string   `json:"HostName"`
	DNSName      string   `json:"DNSName"`
	OS           string   `json:"OS"`
	TailscaleIPs []string `json:"TailscaleIPs"`
	Online       bool     `json:"Online"`
}

type tailscaleStatus struct {
	BackendState string                      `json:"BackendState"`
	Self         *tailscaleDevice            `json:"Self"`
	Peer         map[string]*tailscaleDevice `json:"Peer"`
}

type deviceRow struct {
	item   api.Item
	online bool
	title  string
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       machinesCommandID,
		Title:    "Tailscale Machines",
		Subtitle: "Browse devices and copy their MagicDNS hostnames",
		Aliases:  []string{"Tailscale Devices"},
		Icon:     "network",
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case machinesCommandID:
		return machinesResult(), nil
	case refreshMachinesID:
		items, err := loadDevices(ctx)
		if err != nil {
			return api.Result{}, err
		}
		return api.Result{Patch: &api.ViewPatch{Mode: api.PatchReplace, Items: items}}, nil
	case hostnameUnavailID:
		return api.Result{}, errors.New("This device has no MagicDNS hostname reported by Tailscale.")
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func LoadItems(ctx api.Context, loader string) ([]api.Item, error) {
	return loadDevices(ctx)
}

func machinesResult() api.Result {
	view := api.ListView("Tailscale Machines")
	view.Placeholder = "Search devices, hostnames, or IPs…"
	view.Source = &api.DataSource{Loader: machinesLoader, Retry: true}
	view.EmptyView = &api.EmptyState{Title: "No Tailscale devices", Subtitle: "Connect Tailscale and sign in to your tailnet."}
	view.Refresh = &api.Refresh{IntervalMs: refreshIntervalMs, Mode: api.PatchReplace, Ref: &api.ActionRef{ID: refreshMachinesID}}
	return api.Result{View: &view, Navigation: api.NavPush}
}

func loadDevices(ctx api.Context) ([]api.Item, error) {
	binary, err := tailscaleBinary(ctx)
	if err != nil {
		return nil, err
	}
	result, err := ctx.Desktop().Shell().Exec(binary, []string{"status", "--json"}, api.ShellOptions{TimeoutMs: statusTimeoutMs, OutputLimit: statusOutputLimit})
	if err != nil {
		return nil, err
	}
	if result.ExitCode != 0 {
		return nil, fmt.Errorf("Could not read Tailscale devices: %s", orDefault(firstNonEmptyTrimmed(result.Stderr, result.Stdout), "Tailscale is not running."))
	}
	status, err := parseStatus(result.Stdout)
	if err != nil {
		return nil, err
	}
	return deviceItems(ctx, status), nil
}

func parseStatus(output string) (tailscaleStatus, error) {
	var status tailscaleStatus
	if err := json.Unmarshal([]byte(output), &status); err != nil {
		return tailscaleStatus{}, errors.New("Tailscale returned invalid status data.")
	}
	if status.BackendState == "NeedsLogin" || status.BackendState == "NeedsMachineAuth" {
		return tailscaleStatus{}, errors.New("Sign in to Tailscale and authorize this machine, then try again.")
	}
	return status, nil
}

func tailscaleBinary(ctx api.Context) (string, error) {
	if cached, found := ctx.Cache().Get(tailscaleCacheKey); found {
		if binary, ok := cached.(string); ok && binary != "" {
			return binary, nil
		}
	}
	for _, candidate := range tailscaleCandidates {
		found, err := ctx.Desktop().Shell().Which(candidate)
		if err != nil || found.ExitCode != 0 || strings.TrimSpace(found.Stdout) == "" {
			continue
		}
		binary := strings.Split(strings.TrimSpace(found.Stdout), "\n")[0]
		ctx.Cache().Set(tailscaleCacheKey, binary, binaryCacheTTL)
		return binary, nil
	}
	return "", errors.New("Tailscale was not found. Install the Tailscale app or CLI, sign in, and try again.")
}

func deviceItems(ctx api.Context, status tailscaleStatus) []api.Item {
	var rows []deviceRow
	seen := map[string]bool{}
	for _, entry := range orderedDevices(status) {
		row := deviceRowFor(ctx, entry.device, entry.self, entry.key)
		if seen[row.item.ID] {
			continue
		}
		seen[row.item.ID] = true
		rows = append(rows, row)
	}
	sort.SliceStable(rows, func(i, j int) bool {
		if rows[i].online != rows[j].online {
			return rows[i].online
		}
		return strings.ToLower(rows[i].title) < strings.ToLower(rows[j].title)
	})
	items := make([]api.Item, 0, len(rows))
	for _, row := range rows {
		items = append(items, row.item)
	}
	return items
}

type namedDevice struct {
	device *tailscaleDevice
	self   bool
	key    string
}

func orderedDevices(status tailscaleStatus) []namedDevice {
	var devices []namedDevice
	if status.Self != nil {
		devices = append(devices, namedDevice{device: status.Self, self: true, key: "self"})
	}
	keys := make([]string, 0, len(status.Peer))
	for key := range status.Peer {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		if device := status.Peer[key]; device != nil {
			devices = append(devices, namedDevice{device: device, key: key})
		}
	}
	return devices
}

func deviceRowFor(ctx api.Context, device *tailscaleDevice, self bool, key string) deviceRow {
	dns := strings.TrimRight(device.DNSName, ".")
	ip, ips := preferredAddress(device.TailscaleIPs)
	id := orDefault(orDefault(orDefault(device.ID, device.PublicKey), dns), key)
	title := orDefault(orDefault(orDefault(strings.Split(dns, ".")[0], device.HostName), ip), "Unnamed device")
	online := device.Online
	item := api.Item{
		ID:       id,
		Title:    title,
		Subtitle: joinNonEmpty(orDefault(dns, "No MagicDNS hostname"), ip),
		Icon:     "monitor",
		Keywords: append([]string{device.HostName, dns, device.OS}, ips...),
		Primary:  api.Primary(hostnameAction(dns)),
		Actions:  addressActions(ip, ips),
	}
	if self {
		item.Icon = "laptop"
	}
	if online {
		item.Appearance = &api.Appearance{Foreground: api.ColorGreen}
	}
	item.Accessories = accessoriesFor(self, online)
	return deviceRow{item: item, online: online, title: title}
}

func preferredAddress(ips []string) (string, []string) {
	for _, ip := range ips {
		if !strings.Contains(ip, ":") {
			return ip, ips
		}
	}
	if len(ips) > 0 {
		return ips[0], ips
	}
	return "", ips
}

func hostnameAction(dns string) api.Action {
	if dns == "" {
		return api.Run(hostnameUnavailID, "Hostname Unavailable", nil)
	}
	return api.CopyText("Copy .ts.net Hostname", dns, false)
}

func addressActions(ip string, ips []string) []api.Action {
	if ip == "" {
		return nil
	}
	actions := []api.Action{api.CopyText("Copy IP", ip, false)}
	for _, address := range ips {
		if address != ip {
			actions = append(actions, api.CopyText("Copy IPv6", address, false))
		}
	}
	return actions
}

func accessoriesFor(self, online bool) []api.Accessory {
	var accessories []api.Accessory
	if self {
		accessories = append(accessories, api.Accessory{Text: "This device", Tone: api.ToneMuted})
	}
	if online {
		return append(accessories, api.Accessory{Text: "Online", Tone: api.ToneSuccess})
	}
	return append(accessories, api.Accessory{Text: "Offline", Tone: api.ToneMuted})
}

func joinNonEmpty(parts ...string) string {
	var kept []string
	for _, part := range parts {
		if part != "" {
			kept = append(kept, part)
		}
	}
	return strings.Join(kept, subtitleSeparator)
}

func firstNonEmptyTrimmed(values ...string) string {
	for _, value := range values {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			return trimmed
		}
	}
	return ""
}

func orDefault(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}
