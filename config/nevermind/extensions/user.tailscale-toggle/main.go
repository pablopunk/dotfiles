package main

import (
	"encoding/json"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{
		{ID: "toggle", Title: "Toggle Tailscale", Subtitle: "Bring Tailscale up or down with current settings", Keywords: []string{"tailscale", "toggle", "up", "down", "vpn"}, Icon: "wifi"},
		{ID: "up", Title: "Tailscale Up", Subtitle: "Bring Tailscale up with current settings", Keywords: []string{"tailscale", "up", "vpn", "connect"}, Icon: "wifi"},
		{ID: "down", Title: "Tailscale Down", Subtitle: "Take Tailscale down", Keywords: []string{"tailscale", "down", "vpn", "disconnect"}, Icon: "wifi-off"},
	}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	id := in.Ref.ID
	if id != "toggle" && id != "up" && id != "down" {
		return api.Result{}, nil
	}
	bin, running, state, found := currentState(ctx)
	if !found {
		v := api.ErrorView("Tailscale not found", "Could not find the tailscale binary. Install Tailscale or make sure tailscale is on PATH.")
		return api.Result{View: &v}, nil
	}
	target := id
	if id == "toggle" {
		if running {
			target = "down"
		} else {
			target = "up"
		}
	}
	if target == "up" && running {
		return api.Result{Toast: &api.Toast{Message: "Tailscale is already up (" + state + ")"}}, nil
	}
	if target == "down" && !running {
		return api.Result{Toast: &api.Toast{Message: "Tailscale is already down (" + state + ")"}}, nil
	}
	out, errMsg := runTailscale(ctx, bin, target)
	if errMsg != "" {
		v := api.ErrorView("Tailscale "+target+" failed", errMsg+"\n\n"+out)
		return api.Result{View: &v}, nil
	}
	if target == "up" {
		return api.Result{Toast: &api.Toast{Message: "Tailscale up — using current settings"}}, nil
	}
	return api.Result{Toast: &api.Toast{Message: "Tailscale down"}}, nil
}

func candidates(ctx api.Context) []string {
	cands := []string{}
	if r, err := ctx.Desktop().Shell().Which("tailscale"); err == nil && r.ExitCode == 0 {
		p := strings.TrimSpace(r.Stdout)
		if p != "" {
			cands = append(cands, p)
		}
	}
	cands = append(cands, "/Applications/Tailscale.app/Contents/MacOS/Tailscale", "/opt/homebrew/bin/tailscale", "/usr/local/bin/tailscale", "tailscale")
	seen := map[string]bool{}
	out := []string{}
	for _, c := range cands {
		if !seen[c] {
			seen[c] = true
			out = append(out, c)
		}
	}
	return out
}

func isNotFound(text string) bool {
	t := strings.ToLower(text)
	return strings.Contains(t, "not found") || strings.Contains(t, "no such file") || strings.Contains(t, "executable file not found")
}

func currentState(ctx api.Context) (string, bool, string, bool) {
	sh := ctx.Desktop().Shell()
	for _, bin := range candidates(ctx) {
		r, err := sh.Exec(bin, []string{"status", "--json"}, api.ShellOptions{TimeoutMs: 8000, OutputLimit: 65536})
		combined := ""
		if r.Stdout != "" {
			combined = r.Stdout + " " + r.Stderr
		} else if err != nil {
			combined = err.Error()
		}
		if err != nil && r.Stdout == "" && isNotFound(combined+r.Stderr) {
			continue
		}
		var st struct {
			BackendState string `json:"BackendState"`
		}
		if json.Unmarshal([]byte(r.Stdout), &st) == nil && st.BackendState != "" {
			return bin, st.BackendState == "Running", st.BackendState, true
		}
		if r.Stdout != "" {
			low := strings.ToLower(r.Stdout)
			if strings.Contains(low, "stopped") || strings.Contains(low, "tailscale is stopped") || strings.Contains(low, "no state") {
				return bin, false, "Stopped", true
			}
			return bin, true, "Running", true
		}
		if err == nil && r.ExitCode == 0 {
			return bin, true, "Running", true
		}
		if isNotFound(combined) {
			continue
		}
		if r.Stdout == "" && err != nil {
			continue
		}
		return bin, false, "Stopped", true
	}
	return "", false, "", false
}

func runTailscale(ctx api.Context, bin string, target string) (string, string) {
	r, err := ctx.Desktop().Shell().Exec(bin, []string{target}, api.ShellOptions{TimeoutMs: 30000, OutputLimit: 65536})
	out := strings.TrimSpace(r.Stdout + "\n" + r.Stderr)
	out = strings.TrimSpace(out)
	if err != nil {
		if r.ExitCode != 0 {
			return out, "tailscale " + target + " exited with code " + strings.TrimSpace(out)
		}
		return out, strings.TrimSpace(err.Error())
	}
	if r.ExitCode != 0 {
		if out == "" {
			out = "exit code " + itoa(r.ExitCode)
		}
		return out, "tailscale " + target + " failed: " + out
	}
	return out, ""
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	neg := false
	if n < 0 {
		neg = true
		n = -n
	}
	buf := []byte{}
	for n > 0 {
		buf = append([]byte{byte('0' + n%10)}, buf...)
		n = n / 10
	}
	if neg {
		buf = append([]byte{'-'}, buf...)
	}
	return string(buf)
}
