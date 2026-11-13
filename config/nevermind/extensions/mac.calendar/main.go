package main

import (
	"fmt"
	"regexp"
	"time"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	upcomingCommandID = "upcoming-events"
	rootEventsKey     = "root-events-30m"
	cachedEventsKey   = "calendar-events-24h"
	calendarAppPath   = "/System/Applications/Calendar.app"
	rootWindowMinutes = 30
	fullDayMinutes    = 1440
	refreshIntervalMs = 60000
)

// eventsScript lists the day's events from EventKit as JSON. The minutes argument is replaced before each run.
const eventsScript = `
use AppleScript version "2.4"
use scripting additions
use framework "Foundation"
use framework "EventKit"


on run argv
    set minutesOut to 1440
    try
        set minutesOut to (item 1 of argv) as integer
    end try
    
    set now to current application's NSDate's |date|()
    set calendar to current application's NSCalendar's currentCalendar()
    set startOfToday to calendar's startOfDayForDate:now
    set delta to now's dateByAddingTimeInterval:(minutesOut * 60)

    set eventStore to current application's EKEventStore's alloc()'s init()
    eventStore's requestAccessToEntityType:0 completion:(missing value)

    set thePredicate to eventStore's predicateForEventsWithStartDate:startOfToday endDate:delta calendars:(missing value)
    set theEvents to (eventStore's eventsMatchingPredicate:thePredicate)

    set resultList to current application's NSMutableArray's array()
    repeat with anEvent in theEvents
        set dict to current application's NSMutableDictionary's dictionary()
        dict's setObject:(anEvent's title()) forKey:"title"
        dict's setObject:(anEvent's startDate()) forKey:"startDate"
        dict's setObject:(anEvent's endDate()) forKey:"endDate"
        
        try
            set isAllDayVal to (anEvent's valueForKey:"allDay")
            dict's setObject:isAllDayVal forKey:"isAllDay"
        on error
            dict's setObject:false forKey:"isAllDay"
        end try
        
        set loc to anEvent's location()
        if loc is not missing value then dict's setObject:loc forKey:"location"
        
        set urlVal to anEvent's |URL|()
        if urlVal is not missing value then dict's setObject:(urlVal's absoluteString()) forKey:"url"

        set notes to anEvent's notes()
        if notes is not missing value then dict's setObject:notes forKey:"notes"
        
        set cal to anEvent's calendar()
        dict's setObject:(cal's title()) forKey:"calendar"

        resultList's addObject:dict
    end repeat

    set sortDescriptor to current application's NSSortDescriptor's sortDescriptorWithKey:"startDate" ascending:true
    resultList's sortUsingDescriptors:{sortDescriptor}

    set finalOutput to current application's NSMutableArray's array()
    set isoFormatter to current application's NSISO8601DateFormatter's alloc()'s init()

    repeat with dict in resultList
        set outDict to current application's NSMutableDictionary's dictionary()
        outDict's setObject:(dict's objectForKey:"title") forKey:"title"
        
        set startISO to (isoFormatter's stringFromDate:(dict's objectForKey:"startDate")) as string
        set endISO to (isoFormatter's stringFromDate:(dict's objectForKey:"endDate")) as string
        
        outDict's setObject:startISO forKey:"startISO"
        outDict's setObject:endISO forKey:"endISO"
        
        set loc to dict's objectForKey:"location"
        if loc is not missing value then outDict's setObject:loc forKey:"location"

        set u to dict's objectForKey:"url"
        if u is not missing value then outDict's setObject:u forKey:"url"

        set n to dict's objectForKey:"notes"
        if n is not missing value then outDict's setObject:n forKey:"notes"
        
        set calName to dict's objectForKey:"calendar"
        if calName is not missing value then outDict's setObject:calName forKey:"calendar"
        
        set ad to dict's objectForKey:"isAllDay"
        if ad is not missing value then
            outDict's setObject:ad forKey:"isAllDay"
        else
            outDict's setObject:false forKey:"isAllDay"
        end if
        
        finalOutput's addObject:outDict
    end repeat

    set jsonData to current application's NSJSONSerialization's dataWithJSONObject:finalOutput options:0 |error|:(missing value)
    set jsonString to current application's NSString's alloc()'s initWithData:jsonData encoding:(current application's NSUTF8StringEncoding)
    return jsonString as string
end run
`

var meetingPattern = regexp.MustCompile(`(?i)https?://(?:[a-zA-Z0-9-]+\.)?(?:zoom\.us|meet\.google\.com|teams\.microsoft\.com|webex\.com|slack\.com)/[^\s"'>]+`)

var directMeetingHosts = []string{"zoom.us", "meet.google.com", "teams.microsoft.com"}

type calendarEvent struct {
	Title    string `json:"title"`
	StartISO string `json:"startISO"`
	EndISO   string `json:"endISO"`
	Location string `json:"location"`
	Calendar string `json:"calendar"`
	URL      string `json:"url"`
	Notes    string `json:"notes"`
	IsAllDay any    `json:"isAllDay"`
}

// timing says where "now" falls for an event. It drives the row's score and foreground.
type timing int

const (
	upcomingEvent timing = iota
	ongoingEvent
	pastEvent
)

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{ID: upcomingCommandID, Title: "Upcoming Events", Icon: "calendar-days"}}, nil
}

// RootItems lists the events that are ongoing or start within 15 minutes. The fetch is memoized for 30 seconds.
func RootItems(ctx api.Context) ([]api.Item, error) {
	var events []calendarEvent
	err := ctx.Storage().Memo(rootEventsKey, 30*time.Second, &events, func() (any, error) {
		return fetchEvents(ctx, rootWindowMinutes), nil
	})
	if err != nil || len(events) == 0 {
		return nil, err
	}
	return rootItems(ctx, events), nil
}

func rootItems(ctx api.Context, events []calendarEvent) []api.Item {
	now := ctx.Clock().Now()
	var items []api.Item
	for index, event := range events {
		start, end := event.span()
		ongoing := timingOf(now, start, end) == ongoingEvent
		soon := start.After(now) && start.Sub(now) <= 15*time.Minute
		if !ongoing && !soon {
			continue
		}
		link := meetingLink(event)
		status, score, foreground := "Soon", 110-float64(index), api.ColorBlue
		if ongoing {
			status, score, foreground = "Ongoing", 120-float64(index), api.ColorGreen
		}
		subtitle := fmt.Sprintf("%s (%s)", status, timeRangeLabel(event, start, end))
		if event.Location != "" {
			subtitle += " @ " + event.Location
		}
		items = append(items, api.Item{
			ID:          fmt.Sprintf("cal-root-%d", index),
			Title:       event.Title,
			Subtitle:    subtitle,
			Icon:        iconFor(link),
			Score:       score,
			Accessories: calendarAccessories(event),
			Appearance:  &api.Appearance{Foreground: foreground},
			Primary:     api.Primary(joinOrOpen(link)),
		})
	}
	return items
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	if in.Ref.ID != upcomingCommandID {
		return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
	}
	if in.Launch.Refresh || in.Launch.Reason == "refresh" {
		return refreshPatch(ctx)
	}
	return upcomingResult(ctx)
}

// upcomingResult paints the cached day at once, fetching it only when the cache is empty. The host refreshes it every minute.
func upcomingResult(ctx api.Context) (api.Result, error) {
	var cached []calendarEvent
	if _, err := ctx.Storage().Get(cachedEventsKey, &cached); err != nil {
		return api.Result{}, err
	}
	if len(cached) == 0 {
		cached = fetchEvents(ctx, fullDayMinutes)
		if err := ctx.Storage().Set(cachedEventsKey, cached); err != nil {
			return api.Result{}, err
		}
	}
	items := eventItems(ctx, cached)
	view := api.ListView("Upcoming Events", items...)
	view.SelectedItemID = selectedEventID(items)
	view.EmptyView = emptyDay()
	view.Refresh = &api.Refresh{Immediate: true, IntervalMs: refreshIntervalMs, Mode: api.PatchReplace, Ref: &api.ActionRef{ID: upcomingCommandID}}
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

// refreshPatch fetches the day again and replaces the visible rows in place.
func refreshPatch(ctx api.Context) (api.Result, error) {
	events := fetchEvents(ctx, fullDayMinutes)
	if err := ctx.Storage().Set(cachedEventsKey, events); err != nil {
		return api.Result{}, err
	}
	items := eventItems(ctx, events)
	return api.Result{Patch: &api.ViewPatch{Mode: api.PatchReplace, Items: items, SelectedItemID: selectedEventID(items)}}, nil
}

func emptyDay() *api.EmptyState {
	return &api.EmptyState{Title: "No upcoming events", Subtitle: "Your calendar is clear for the next 24 hours."}
}

func eventItems(ctx api.Context, events []calendarEvent) []api.Item {
	now := ctx.Clock().Now()
	items := make([]api.Item, 0, len(events))
	for index, event := range events {
		items = append(items, eventItem(event, index, now))
	}
	return items
}

func eventItem(event calendarEvent, index int, now time.Time) api.Item {
	start, end := event.span()
	link := meetingLink(event)
	score, foreground := eventRank(index, timingOf(now, start, end), event.allDay())
	item := api.Item{
		ID:          fmt.Sprintf("event-%d", index),
		Title:       event.Title,
		Subtitle:    timeRangeLabel(event, start, end),
		Accessories: calendarAccessories(event),
		Icon:        iconFor(link),
		Score:       score,
		Primary:     api.Primary(joinOrOpen(link)),
		Actions:     eventActions(event, link),
	}
	if foreground != "" {
		item.Appearance = &api.Appearance{Foreground: foreground}
	}
	return item
}

// eventRank returns the score and foreground of one event. Scores are ordered so that selectedEventID finds the
// first ongoing or upcoming timed event.
func eventRank(index int, state timing, allDay bool) (float64, api.Color) {
	i := float64(index)
	switch {
	case state == pastEvent:
		return 20 - i, ""
	case state == ongoingEvent && allDay:
		return 250 - i, ""
	case state == ongoingEvent:
		return 200 - i, api.ColorGreen
	case allDay:
		return 240 - i, api.ColorBlue
	}
	return 100 - i, api.ColorBlue
}

func selectedEventID(items []api.Item) string {
	for _, item := range items {
		if item.Score <= 200 && item.Score > 20 {
			return item.ID
		}
	}
	if len(items) > 0 {
		return items[0].ID
	}
	return ""
}
