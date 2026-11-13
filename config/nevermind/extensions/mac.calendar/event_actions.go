package main

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func eventActions(event calendarEvent, link string) []api.Action {
	var actions []api.Action
	if link != "" {
		actions = append(actions, api.OpenURL("Join Meeting", link))
	}
	actions = append(actions, api.OpenPath("Open Calendar", calendarAppPath), api.CopyText("Copy Title", event.Title, false))
	if link != "" {
		actions = append(actions, api.CopyText("Copy Meeting Link", link, false))
	}
	if event.Location != "" {
		actions = append(actions, api.CopyText("Copy Location", event.Location, false))
	}
	return actions
}

func calendarAccessories(event calendarEvent) []api.Accessory {
	if event.Calendar == "" {
		return nil
	}
	return []api.Accessory{{Text: event.Calendar}}
}

func fetchEvents(ctx api.Context, minutes int) []calendarEvent {
	script := strings.Replace(eventsScript, "set minutesOut to 1440", fmt.Sprintf("set minutesOut to %d", minutes), 1)
	result, err := ctx.Desktop().Shell().AppleScript(script, api.ShellOptions{})
	if err != nil {
		ctx.Logs().Log(api.LogError, "Error fetching events", err.Error())
		return nil
	}
	if result.ExitCode != 0 {
		ctx.Logs().Log(api.LogError, "Calendar script failed", result.Stderr)
		return nil
	}
	var events []calendarEvent
	if err := json.Unmarshal([]byte(result.Stdout), &events); err != nil {
		ctx.Logs().Log(api.LogError, "Error fetching events", err.Error())
		return nil
	}
	return events
}

func (event calendarEvent) span() (time.Time, time.Time) {
	return parseISO(event.StartISO), parseISO(event.EndISO)
}

func (event calendarEvent) allDay() bool {
	switch value := event.IsAllDay.(type) {
	case bool:
		return value
	case float64:
		return value == 1
	case string:
		return value == "true"
	}
	return false
}

func parseISO(value string) time.Time {
	parsed, _ := time.Parse(time.RFC3339, value)
	return parsed
}

func timingOf(now, start, end time.Time) timing {
	switch {
	case now.After(end):
		return pastEvent
	case !now.Before(start):
		return ongoingEvent
	}
	return upcomingEvent
}

func timeRangeLabel(event calendarEvent, start, end time.Time) string {
	if event.allDay() {
		return "All Day"
	}
	return start.Local().Format("15:04") + " - " + end.Local().Format("15:04")
}

// meetingLink returns the first video-meeting URL in the event's link, location or notes.
func meetingLink(event calendarEvent) string {
	for _, host := range directMeetingHosts {
		if strings.Contains(event.URL, host) {
			return event.URL
		}
	}
	for _, target := range []string{event.Location, event.Notes, event.URL} {
		if match := meetingPattern.FindString(target); match != "" {
			return match
		}
	}
	return ""
}

func joinOrOpen(link string) api.Action {
	if link != "" {
		return api.OpenURL("Join Meeting", link)
	}
	return api.OpenPath("Open Calendar", calendarAppPath)
}

func iconFor(link string) string {
	if link != "" {
		return "video"
	}
	return "calendar"
}
