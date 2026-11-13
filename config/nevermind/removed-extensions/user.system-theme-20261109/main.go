package main

import (
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func toggleItem() api.Item {
	run := api.Run("toggle-theme", "Toggle theme", nil)
	return api.Item{
		ID:       "toggle-theme",
		Title:    "Toggle System Theme",
		Subtitle: "Switch between light and dark mode",
		Icon:     "moon",
		Keywords: []string{"theme", "dark", "light", "toggle", "mode", "appearance"},
		Primary:  api.Primary(run),
	}
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{
		{
			ID:       "toggle-theme",
			Title:    "Toggle System Theme",
			Subtitle: "Switch light / dark mode",
			Keywords: []string{"theme", "dark", "light", "toggle", "mode", "appearance"},
			Icon:     "moon",
			Mode:     api.ModeNoView,
			Actions:  []api.Action{api.Run("toggle-theme", "Toggle theme", nil)},
		},
	}, nil
}

func RootItems(ctx api.Context) ([]api.Item, error) {
	return []api.Item{toggleItem()}, nil
}

func SearchItems(ctx api.Context, query string) ([]api.Item, error) {
	q := strings.ToLower(strings.TrimSpace(query))
	if len(q) < 2 {
		return nil, nil
	}
	if !(strings.Contains(q, "theme") || strings.Contains(q, "dark") || strings.Contains(q, "light") || strings.Contains(q, "toggle") || strings.Contains(q, "mode") || strings.Contains(q, "appearance")) {
		return nil, nil
	}
	return []api.Item{toggleItem()}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	if in.Ref.ID != "toggle-theme" {
		return api.Result{}, nil
	}
	osName := strings.ToLower(ctx.System().OS())
	var err error
	if strings.Contains(osName, "darwin") || strings.Contains(osName, "mac") {
		err = toggleMac(ctx)
	} else if strings.Contains(osName, "win") {
		err = toggleWindows(ctx)
	} else {
		err = toggleLinux(ctx)
	}
	if err != nil {
		return api.Result{Toast: &api.Toast{Message: "Could not toggle theme: " + err.Error()}}, nil
	}
	return api.Result{Toast: &api.Toast{Message: "Toggled system theme"}}, nil
}

func toggleMac(ctx api.Context) error {
	_, err := ctx.Desktop().Shell().AppleScript(`tell application "System Events" to tell appearance preferences to set dark mode to not dark mode`, api.ShellOptions{})
	return err
}

func toggleLinux(ctx api.Context) error {
	sh := ctx.Desktop().Shell()
	cur, err := sh.Exec("gsettings", []string{"get", "org.gnome.desktop.interface", "color-scheme"}, api.ShellOptions{})
	if err == nil {
		isDark := strings.Contains(strings.ToLower(cur.Stdout), "dark")
		newVal := "prefer-dark"
		if isDark {
			newVal = "default"
		}
		_, err = sh.Exec("gsettings", []string{"set", "org.gnome.desktop.interface", "color-scheme", newVal}, api.ShellOptions{})
		if err == nil {
			return nil
		}
	}
	cur2, err2 := sh.Exec("gsettings", []string{"get", "org.gnome.desktop.interface", "gtk-theme"}, api.ShellOptions{})
	if err2 != nil {
		if err != nil {
			return err
		}
		return err2
	}
	isDark2 := strings.Contains(strings.ToLower(cur2.Stdout), "dark")
	newTheme := "Adwaita-dark"
	if isDark2 {
		newTheme = "Adwaita"
	}
	_, err3 := sh.Exec("gsettings", []string{"set", "org.gnome.desktop.interface", "gtk-theme", newTheme}, api.ShellOptions{})
	return err3
}

func toggleWindows(ctx api.Context) error {
	ps := `$p='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize';$v=(Get-ItemProperty -Path $p -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme;if($null -eq $v){$v=1};$n=1-$v;Set-ItemProperty -Path $p -Name AppsUseLightTheme -Value $n;Set-ItemProperty -Path $p -Name SystemUsesLightTheme -Value $n`
	_, err := ctx.Desktop().Shell().Exec("powershell", []string{"-NoProfile", "-Command", ps}, api.ShellOptions{})
	return err
}
