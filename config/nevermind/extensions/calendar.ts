import type { NevermindExtension, ExtensionContext, ExtensionItem } from './nevermind-extension-api'

const FETCH_EVENTS_JSON_SCRIPT = `
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

interface CalendarEvent {
  title: string
  startISO: string
  endISO: string
  location?: string
  calendar?: string
  url?: string
  notes?: string
  isAllDay?: boolean | number
}

function findMeetingLink(event: CalendarEvent): string | undefined {
  if (event.url && (event.url.includes('zoom.us') || event.url.includes('meet.google.com') || event.url.includes('teams.microsoft.com'))) {
    return event.url
  }
  const searchTargets = [event.location, event.notes, event.url].filter(Boolean) as string[]
  const linkRegex = /https?:\/\/(?:[a-zA-Z0-9-]+\.)?(?:zoom\.us|meet\.google\.com|teams\.microsoft\.com|webex\.com|slack\.com)\/[^\s"'>]+/gi
  for (const target of searchTargets) {
    const match = target.match(linkRegex)
    if (match) return match[0]
  }
  return undefined
}

async function fetchEvents(ctx: ExtensionContext, minutes: number): Promise<CalendarEvent[]> {
  try {
    const scriptWithArgs = FETCH_EVENTS_JSON_SCRIPT.replace('set minutesOut to 1440', `set minutesOut to ${minutes}`)
    const execResult = await ctx.desktop.shell?.appleScript(scriptWithArgs)
    if (!execResult || execResult.exitCode !== 0) {
      ctx.logs.error('Calendar script failed', execResult?.stderr)
      return []
    }
    return JSON.parse(execResult.stdout) as CalendarEvent[]
  } catch (e) {
    ctx.logs.error('Error fetching events', e)
    return []
  }
}

function formatTime(isoString: string): string {
  try {
    const d = new Date(isoString)
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false })
  } catch {
    return ''
  }
}

function eventsToItems(ctx: ExtensionContext, events: CalendarEvent[]): ExtensionItem[] {
  const now = Date.now()
  return events.map((event, i) => {
    const meetingLink = findMeetingLink(event)
    const startTime = new Date(event.startISO).getTime()
    const endTime = new Date(event.endISO).getTime()
    const isAllDay = event.isAllDay === true || event.isAllDay === 1 || String(event.isAllDay) === 'true'
    const isOngoing = now >= startTime && now <= endTime
    const isPast = now > endTime

    let color: 'green' | 'blue' | undefined = 'blue'
    let score = 100 - i

    if (isPast) {
      color = undefined
      score = 20 - i
    } else if (isOngoing) {
      color = isAllDay ? undefined : 'green'
      score = isAllDay ? 250 - i : 200 - i
    } else if (isAllDay) {
      score = 240 - i
    }

    return {
      id: `event-${i}`,
      title: event.title,
      subtitle: isAllDay
        ? 'All Day'
        : `${formatTime(event.startISO)} - ${formatTime(event.endISO)}`,
      accessories: event.calendar ? [{ text: event.calendar }] : [],
      appearance: color ? { foreground: color } : undefined,
      icon: meetingLink ? 'video' : 'calendar',
      score,
      primaryAction: meetingLink
        ? ctx.actions.openUrl(meetingLink, 'Join Meeting')
        : ctx.actions.openUrl('calendar://', 'Open Calendar'),
      actions: [
        meetingLink ? ctx.actions.openUrl(meetingLink, 'Join Meeting') : undefined,
        ctx.actions.openUrl('calendar://', 'Open Calendar'),
        ctx.actions.copyText(event.title, 'Copy Title'),
        meetingLink ? ctx.actions.copyText(meetingLink, 'Copy Meeting Link') : undefined,
        event.location ? ctx.actions.copyText(event.location, 'Copy Location') : undefined,
      ].filter(Boolean) as any,
    }
  })
}

function getSelectedEventId(items: ExtensionItem[]): string | undefined {
  // Select the first ongoing timed event or first upcoming timed event.
  // Ongoing timed events have score (200 - i).
  // Future timed events have score (100 - i).
  // Past events have score (20 - i).
  // All-day events have score 250/240.
  const target = items.find((item) => {
    const score = item.score ?? 0
    return score <= 200 && score > 20
  })
  return target?.id || items[0]?.id
}

export default {
  id: 'mac.calendar',
  title: 'Calendar',
  permissions: ['system'],

  async rootItems(ctx) {
    const events = await ctx.storage.memo('root-events-30m', 30000, () => fetchEvents(ctx, 30))
    if (!events || events.length === 0) return []

    const now = Date.now()
    const activeRootItems: ExtensionItem[] = []

    events.forEach((event, index) => {
      const startTime = new Date(event.startISO).getTime()
      const endTime = new Date(event.endISO).getTime()
      const isAllDay = event.isAllDay === true || event.isAllDay === 1 || String(event.isAllDay) === 'true'

      const isOngoing = now >= startTime && now <= endTime
      const isUpcomingSoon = startTime > now && (startTime - now) <= 15 * 60 * 1000

      if (isOngoing || isUpcomingSoon) {
        const meetingLink = findMeetingLink(event)
        const timeStr = isAllDay
          ? 'All Day'
          : `${formatTime(event.startISO)} - ${formatTime(event.endISO)}`

        activeRootItems.push({
          id: `cal-root-${index}`,
          title: event.title,
          subtitle: `${isOngoing ? 'Ongoing' : 'Soon'} (${timeStr})${event.location ? ` @ ${event.location}` : ''}`,
          icon: meetingLink ? 'video' : 'calendar',
          score: isOngoing ? 120 - index : 110 - index,
          accessories: event.calendar ? [{ text: event.calendar }] : [],
          appearance: isOngoing ? { foreground: 'green' } : { foreground: 'blue' },
          primaryAction: meetingLink
            ? ctx.actions.openUrl(meetingLink, 'Join Meeting')
            : ctx.actions.openUrl('calendar://', 'Open Calendar'),
        })
      }
    })

    return activeRootItems
  },

  commands: [
    {
      id: 'upcoming-events',
      title: 'Upcoming Events',
      icon: 'calendar-days',
      async run(ctx) {
        const isRefresh = ctx.launch?.refresh === true || ctx.launch?.reason === 'refresh'

        if (isRefresh) {
          const freshEvents = await fetchEvents(ctx, 1440)
          await ctx.storage.set('calendar-events-24h', freshEvents)
          const items = eventsToItems(ctx, freshEvents)
          const selectedItemId = getSelectedEventId(items)

          return ctx.ui.list({
            title: 'Upcoming Events',
            items,
            selectedItemId,
            emptyView: {
              title: 'No upcoming events',
              subtitle: 'Your calendar is clear for the next 24 hours.',
            },
          })
        }

        const cachedEvents = await ctx.storage.get<CalendarEvent[]>('calendar-events-24h') || []

        if (cachedEvents.length === 0) {
          const freshEvents = await fetchEvents(ctx, 1440)
          await ctx.storage.set('calendar-events-24h', freshEvents)
          const items = eventsToItems(ctx, freshEvents)
          const selectedItemId = getSelectedEventId(items)

          return ctx.ui.list({
            title: 'Upcoming Events',
            items,
            selectedItemId,
            refresh: {
              immediate: true,
              intervalMs: 60000,
            },
            emptyView: {
              title: 'No upcoming events',
              subtitle: 'Your calendar is clear for the next 24 hours.',
            },
          })
        }

        const items = eventsToItems(ctx, cachedEvents)
        const selectedItemId = getSelectedEventId(items)

        return ctx.ui.list({
          title: 'Upcoming Events',
          items,
          selectedItemId,
          refresh: {
            immediate: true,
            intervalMs: 60000,
          },
          emptyView: {
            title: 'No upcoming events',
            subtitle: 'Your calendar is clear for the next 24 hours.',
          },
        })
      },
    },
  ],
} satisfies NevermindExtension
