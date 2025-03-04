load("encoding/json.star", "json")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

#SCHEMA

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "showlife",
                name = "Show Life Bar",
                desc = "Display bar optimistically approximating progress through life",
                icon = "skullCrossbones",
                default = False,
            ),
            schema.Text(
                id = "birthyear",
                name = "Birth Year",
                desc = "Year used to estimate progress through life",
                icon = "baby",
                default = "1990",
            ),
            schema.Toggle(
                id = "showmoon",
                name = "Show Moon Phase",
                desc = "Display phase of the moon for each day of the month",
                icon = "moon",
                default = True,
            ),
            schema.Toggle(
                id = "showweek",
                name = "Show Week Start",
                desc = "Display notches representing the beginning of the next Sunday",
                icon = "calendarWeek",
                default = True,
            ),
            schema.Toggle(
                id = "showsun",
                name = "Show Sun Rise and Set",
                desc = "Display bar showing sunrise and set relative to current hour",
                icon = "sun",
                default = True,
            ),
            schema.Toggle(
                id = "showminute",
                name = "Show Minute Dot",
                desc = "Display dot walking across the bottom corresponding to minute of the hour",
                icon = "clock",
                default = True,
            ),
            schema.Toggle(
                id = "showsecond",
                name = "Show Second Dot",
                desc = "Display dot walking across the bottom corresponding to second of the minute",
                icon = "stopwatch",
                default = True,
            ),
        ],
    )

#/SCHEMA

#UTILS

def drawrect(x, y, w, h, c):
    if w <= 0:
        return render.Box(width = 1, height = 1)
    if h <= 0:
        return render.Box(width = 1, height = 1)
    if x == 0:
        if y == 0:
            return render.Box(width = w, height = h, color = c)
        else:
            return render.Column(
                children = [
                    render.Box(width = 1, height = y),
                    render.Box(width = w, height = h, color = c),
                ],
            )
    if y == 0:
        return render.Row(
            children = [
                render.Box(width = x, height = 1),
                render.Box(width = w, height = h, color = c),
            ],
        )
    return render.Column(
        children = [
            render.Box(width = 1, height = y),
            render.Row(
                children = [
                    render.Box(width = x, height = 1),
                    render.Box(width = w, height = h, color = c),
                ],
            ),
        ],
    )

def drawrectcoords(x0, y0, x1, y1, c):
    return drawrect(x0, y0, x1 - x0 + 1, y1 - y0 + 1, c)

def drawtext(x, y, text):
    if text == "":
        return render.Box(width = 1, height = 1)
    if x == 0:
        if y == 0:
            return render.Row(
                children = [
                    render.Text(text),
                ],
            )
        else:
            return render.Column(
                children = [
                    render.Box(width = 1, height = y),
                    render.Row(
                        children = [
                            render.Text(text),
                        ],
                    ),
                ],
            )
    if y == 0:
        return render.Row(
            children = [
                render.Box(width = x, height = 1),
                render.Text(text),
            ],
        )
    return render.Column(
        children = [
            render.Box(width = 1, height = y),
            render.Row(
                children = [
                    render.Box(width = x, height = 1),
                    render.Text(text),
                ],
            ),
        ],
    )

def drawrtext(x, y, text):
    if text == "":
        return render.Box(width = 1, height = 1)
    x = x + 2
    if x >= 64:
        if y == 0:
            return render.Row(
                expanded = True,
                main_align = "end",
                children = [
                    render.Text(text),
                ],
            )
        else:
            return render.Column(
                children = [
                    render.Box(width = 1, height = y),
                    render.Row(
                        expanded = True,
                        main_align = "end",
                        children = [
                            render.Text(text),
                        ],
                    ),
                ],
            )
    if y == 0:
        return render.Row(
            expanded = True,
            main_align = "end",
            children = [
                render.Text(text),
                render.Box(width = 64 - x, height = 1),
            ],
        )
    return render.Column(
        children = [
            render.Box(width = 1, height = y),
            render.Row(
                expanded = True,
                main_align = "end",
                children = [
                    render.Text(text),
                    render.Box(width = 64 - x, height = 10),
                ],
            ),
        ],
    )

#/UTILS

#STATIC

DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

LUNATION = 2551443  # lunar cycle in seconds (29 days 12 hours 44 minutes 3 seconds)
REF_NEWMOON = time.parse_time("30-Apr-2022 20:28:00", format = "02-Jan-2006 15:04:05").unix
MONTHSTRS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
MONTHSEASON = [0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4]
DAYSOFMONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
WEEKDAYSTRS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

#/STATIC

#CTX

#global weekstartcolor
#global suncolor
#global lifecolor
#global daybgcolor
#global weekdaybgcolor
#global hourbgcolor
#global dayfgcolor
#global weekdayfgcolor
#global hourfgcolor
#global minutecolor
#global secondcolor
#global year
#global month
#global season
#global day
#global weekday
#global hour
#global minute
#global second
#global lifex
#global seasonxs
#global monthxs
#global dayxs
#global weekdayxs
#global hourxs
#global weekxs
#global sunxs
#global mooncolors
#global seasoncolors
#global seasonbcolors

#/CTX

#FUNCS

def yforsun(sunrise, lat, lng, t):
    return (int)(sunrise.elevation(lat, lng, t) * 8 / 90.0)

def moonatday(monthtime, dayoff):
    cycleindex = ((monthtime + (time.hour * 24 * dayoff)).unix - REF_NEWMOON) % LUNATION
    moonp = (cycleindex / LUNATION)
    return ((-math.cos(moonp * 2 * math.pi)) + 1) / 2

def colorformoon(p):
    if p > 0.95:
        return "#888"
    if p > 0.85:
        return "#778"
    if p > 0.75:
        return "#667"
    if p > 0.65:
        return "#556"
    if p > 0.55:
        return "#445"
    if p > 0.45:
        return "#334"
    if p > 0.35:
        return "#223"
    if p > 0.15:
        return "#112"
    return "#001"

#/FUNCS

def main(config):
    ctx = {}
    unow = time.now()

    showlife = config.bool("showlife")
    showmoon = config.bool("showmoon")
    showweek = config.bool("showweek")
    showsun = config.bool("showsun")
    showminute = config.bool("showminute")
    showsecond = config.bool("showsecond")

    def getctx(unow):
        #CONFIG

        location = json.decode(config.get("location", DEFAULT_LOCATION))
        timezone = location["timezone"]
        lat = float(location["lat"])
        lng = float(location["lng"])
        thisnow = unow.in_location(timezone)
        ctx["thisnow"] = thisnow

        birthyear = 1990
        birthyearstr = config.get("birthyear")
        if birthyearstr:
            birthyear = int(birthyearstr)

        springcolor = "#183018"
        summercolor = "#2C2C00"
        fallcolor = "#420"
        wintercolor = "#282838"

        springbcolor = "#8F8"
        summerbcolor = "#AA0"
        fallbcolor = "#F40"
        winterbcolor = "#AAF"

        ctx["weekstartcolor"] = "#FFFFFF18"
        ctx["suncolor"] = "#664A"
        ctx["lifecolor"] = "#400"
        ctx["daybgcolor"] = "#033"
        ctx["weekdaybgcolor"] = "#004"
        ctx["hourbgcolor"] = "#404"
        ctx["dayfgcolor"] = "#0AA"
        ctx["weekdayfgcolor"] = "#00E"
        ctx["hourfgcolor"] = "#B0B"
        ctx["minutecolor"] = "#B88"
        ctx["secondcolor"] = "#AAA"

        #/CONFIG

        #PRECACHING

        #everything 0 indexed
        ctx["year"] = thisnow.year
        ctx["month"] = thisnow.month - 1
        ctx["season"] = MONTHSEASON[ctx["month"]]
        ctx["day"] = thisnow.day - 1
        ctx["weekday"] = humanize.day_of_week(thisnow)
        ctx["hour"] = thisnow.hour
        ctx["minute"] = thisnow.minute
        ctx["second"] = thisnow.second

        ctx["lifex"] = int(64 * (ctx["year"] - birthyear) / 90)

        ctx["seasonxs"] = [
            int(64 * 0 / 12),
            int(64 * 2 / 12),
            int(64 * 5 / 12),
            int(64 * 8 / 12),
            int(64 * 11 / 12),
            int(64 * 12 / 12),
        ]

        ctx["monthxs"] = []
        for i in range(13):
            ctx["monthxs"].append(int(64 * i / 12))
        ctx["monthxs"][12] = 63

        daysthismonth = DAYSOFMONTH[ctx["month"]]
        ctx["dayxs"] = []
        for i in range(32):
            ctx["dayxs"].append(int(64 * i / daysthismonth))
        ctx["dayxs"][daysthismonth] = 63

        ctx["weekdayxs"] = []
        for i in range(8):
            ctx["weekdayxs"].append(int(64 * i / 7))
        ctx["weekdayxs"][7] = 63

        ctx["hourxs"] = []
        for i in range(25):
            ctx["hourxs"].append(int(64 * i / 24))
        ctx["hourxs"][24] = 63

        firstsun = (ctx["day"] + (7 + 7 - ctx["weekday"])) % 7
        ctx["weekxs"] = []
        for i in range(5):
            ctx["weekxs"].append(int(64 * (firstsun + i * 7) / daysthismonth))
        if ctx["weekxs"][3] == 64:
            ctx["weekxs"][3] = 63
        if ctx["weekxs"][4] == 64:
            ctx["weekxs"][4] = 63

        #time.time(year=ctx["year"],month=ctx["month"]+1,day=ctx["day"]+1,hour=ctx["hour"],minute=ctx["minute"],second=ctx["second"]).in_location(timezone)

        rise = sunrise.sunrise(lat, lng, thisnow).in_location(timezone)
        set = sunrise.sunset(lat, lng, thisnow).in_location(timezone)
        risem = rise.hour * 60 + rise.minute
        setm = set.hour * 60 + set.minute
        ctx["sunxs"] = [
            int(64 * risem / (24 * 60)),
            int(64 * setm / (24 * 60)),
        ]
        ctx["sunys"] = []
        thisdaystart = thisnow
        thisdaystart = thisdaystart - time.hour * ctx["hour"]
        thisdaystart = thisdaystart - time.minute * ctx["minute"]
        thisdaystart = thisdaystart - time.second * ctx["second"]
        for i in range(ctx["sunxs"][1] - ctx["sunxs"][0]):
            ctx["sunys"].append(yforsun(sunrise, lat, lng, thisdaystart + (time.minute * ((ctx["sunxs"][0] + i + 1) * (24 * 60)) / 64)))

        thismonthstart = thisnow
        thismonthstart = thismonthstart - time.hour * (ctx["day"] * 24)
        thismonthstart = thismonthstart - time.hour * ctx["hour"]
        thismonthstart = thismonthstart - time.minute * ctx["minute"]
        thismonthstart = thismonthstart - time.second * ctx["second"]
        sincemonthstart = thisnow - thismonthstart
        monthstart = unow - sincemonthstart
        ctx["mooncolors"] = []
        for i in range(32):
            ctx["mooncolors"].append(colorformoon(moonatday(monthstart, i)))

        if lat > 0.0:
            ctx["seasoncolors"] = [
                wintercolor,
                springcolor,
                summercolor,
                fallcolor,
                wintercolor,
            ]
            ctx["seasonbcolors"] = [
                winterbcolor,
                springbcolor,
                summerbcolor,
                fallbcolor,
                winterbcolor,
            ]
        else:
            ctx["seasoncolors"] = [
                summercolor,
                fallcolor,
                wintercolor,
                springcolor,
                summercolor,
            ]
            ctx["seasonbcolors"] = [
                summerbcolor,
                fallbcolor,
                winterbcolor,
                springbcolor,
                summerbcolor,
            ]

        #/PRECACHING

    #RENDERING

    def getstack(showlife, showmoon, showweek, showsun, showminute, showsecond, noanimate):
        stack = []

        #get ctx for simplicity of typing
        thisnow = ctx["thisnow"]
        weekstartcolor = ctx["weekstartcolor"]
        suncolor = ctx["suncolor"]
        lifecolor = ctx["lifecolor"]
        daybgcolor = ctx["daybgcolor"]
        weekdaybgcolor = ctx["weekdaybgcolor"]
        hourbgcolor = ctx["hourbgcolor"]
        dayfgcolor = ctx["dayfgcolor"]
        weekdayfgcolor = ctx["weekdayfgcolor"]
        hourfgcolor = ctx["hourfgcolor"]
        minutecolor = ctx["minutecolor"]
        secondcolor = ctx["secondcolor"]
        month = ctx["month"]
        season = ctx["season"]
        day = ctx["day"]
        weekday = ctx["weekday"]
        hour = ctx["hour"]
        minute = ctx["minute"]
        second = ctx["second"]
        lifex = ctx["lifex"]
        seasonxs = ctx["seasonxs"]
        monthxs = ctx["monthxs"]
        dayxs = ctx["dayxs"]
        weekdayxs = ctx["weekdayxs"]
        hourxs = ctx["hourxs"]
        weekxs = ctx["weekxs"]
        sunxs = ctx["sunxs"]
        sunys = ctx["sunys"]
        mooncolors = ctx["mooncolors"]
        seasoncolors = ctx["seasoncolors"]
        seasonbcolors = ctx["seasonbcolors"]

        #month
        y0 = 0
        y1 = 6
        for i in range(5):
            if seasonxs[i + 1] < monthxs[month + 1]:
                stack.append(drawrectcoords(seasonxs[i], y0, seasonxs[i + 1] - 1, 1, seasoncolors[i]))
            elif seasonxs[i] > monthxs[month]:
                stack.append(drawrectcoords(seasonxs[i], y0, seasonxs[i + 1] - 1, y1, seasoncolors[i]))
            else:
                stack.append(drawrectcoords(seasonxs[i], y0, monthxs[month] - 1, 1, seasoncolors[i]))
                stack.append(drawrectcoords(monthxs[month] + 1, y0, seasonxs[i + 1] - 1, y1, seasoncolors[i]))
        stack.append(drawrect(monthxs[month], y0, 1, y1 - y0 + 1, seasonbcolors[season]))
        stack.append(drawrect(monthxs[month + 1], y0, 1, y1 - y0, seasonbcolors[season]))
        stack.append(drawrect(monthxs[month], y1, 1, 1, "#000"))
        stack.append(drawrect(monthxs[month + 1], y1, 1, 1, "#000"))
        for i in range(11):
            if i != month:
                if i < month:
                    stack.append(drawrect(monthxs[i + 1] - 1, 1, 1, 2, "#000"))
                else:
                    stack.append(drawrect(monthxs[i + 1] - 1, 6, 1, 2, "#000"))
        stack.append(drawrect(monthxs[12], 6, 1, 2, "#000"))  #shift final
        if monthxs[month + 1] >= 32:
            stack.append(drawrtext(monthxs[month] - 2, y0, MONTHSTRS[month]))
        else:
            stack.append(drawtext(monthxs[month + 1] + 2, y0, MONTHSTRS[month]))

        #day
        y0 = 8
        y1 = 15
        stack.append(drawrectcoords(0, y0, dayxs[day + 1], y1, daybgcolor))
        stack.append(drawrect(dayxs[day], y0, 1, 8, dayfgcolor))
        stack.append(drawrect(dayxs[day + 1], y0, 1, 8, dayfgcolor))

        #weekstart
        if showweek:
            for i in range(5):
                stack.append(drawrect(weekxs[i], 13, 1, 3, weekstartcolor))
                stack.append(drawrect(weekxs[i] - 1, 15, 1, 1, weekstartcolor))
                stack.append(drawrect(weekxs[i] + 1, 15, 1, 1, weekstartcolor))
        if dayxs[day + 1] >= 32:
            stack.append(drawrtext(dayxs[day] - 2, y0, str(day + 1)))
        else:
            stack.append(drawtext(dayxs[day + 1] + 2, y0, str(day + 1)))

        #weekday
        y0 = 16
        y1 = 23
        stack.append(drawrectcoords(0, y0, weekdayxs[weekday + 1], y1, weekdaybgcolor))
        stack.append(drawrect(weekdayxs[weekday], y0, 1, 8, weekdayfgcolor))
        stack.append(drawrect(weekdayxs[weekday + 1], y0, 1, 8, weekdayfgcolor))
        if weekdayxs[weekday + 1] >= 32:
            stack.append(drawrtext(weekdayxs[weekday] - 2, y0, WEEKDAYSTRS[weekday]))
        else:
            stack.append(drawtext(weekdayxs[weekday + 1] + 2, y0, WEEKDAYSTRS[weekday]))

        #hour
        y0 = 24
        y1 = 31
        stack.append(drawrectcoords(0, y0, hourxs[hour + 1], y1, hourbgcolor))

        #sunriseset
        if showsun:
            for i in range(sunxs[1] - sunxs[0]):
                stack.append(drawrect(sunxs[0] + i, 31 - sunys[i], 1, 1, suncolor))
        stack.append(drawrect(hourxs[hour], y0, 1, 8, hourfgcolor))
        stack.append(drawrect(hourxs[hour + 1], y0, 1, 8, hourfgcolor))
        if noanimate:
            if hourxs[hour + 1] >= 32:
                stack.append(drawrtext(hourxs[hour] - 2, y0, thisnow.format("3:04PM")))
            else:
                stack.append(drawtext(hourxs[hour + 1] + 2, y0, thisnow.format("3:04PM")))
        else:
            animation = []
            if hourxs[hour + 1] >= 32:
                for i in range(61):
                    animation.append(drawrtext(hourxs[hour] - 2, y0, (thisnow + time.second * i).format("3:04PM")))
            else:
                for i in range(61):
                    animation.append(drawtext(hourxs[hour + 1] + 2, y0, (thisnow + time.second * i).format("3:04PM")))
            stack.append(render.Animation(children = animation))

        #life
        if showlife:
            stack.append(drawrect(0, 0, lifex, 1, lifecolor))

        #moon
        if showmoon:
            for i in range(DAYSOFMONTH[month] + 1):
                stack.append(drawrect(dayxs[i], 8, 1, 1, mooncolors[i]))

        #minute
        if showminute:
            if noanimate:
                stack.append(drawrect(2 + minute, 31, 1, 1, minutecolor))
            else:
                animation = []
                for i in range(61):
                    animation.append(drawrect(2 + (minute + (int)((second + i) / 60)), 31, 1, 1, minutecolor))
                stack.append(render.Animation(children = animation))

        #second
        if showsecond:
            if noanimate:
                stack.append(drawrect(2 + second, 31, 1, 1, secondcolor))
            else:
                animation = []
                for i in range(61):
                    if i == 0:
                        animation.append(drawrect((2 + (second + i) % 60), 31, 1, 1, "#ACA"))
                    else:
                        animation.append(drawrect((2 + (second + i) % 60), 31, 1, 1, secondcolor))
                stack.append(render.Animation(children = animation))

        return render.Stack(stack)

    #DEBUGGING

    #animationstacks = []
    #getctx(unow)
    #animationstacks.append(getstack(showlife,showmoon,showweek,showsun,showminute,showsecond,True))
    #for i in range(300):
    #    getctx(unow+time.minute*3253*i)
    #    animationstacks.append(getstack(showlife,showmoon,showweek,showsun,showminute,showsecond,True))
    #stack = render.Animation(children = animationstacks)

    getctx(unow)
    stack = getstack(showlife, showmoon, showweek, showsun, showminute, showsecond, False)

    return render.Root(
        delay = 1000,
        #delay = 10,
        #show_full_animation = True,
        child = stack,
    )
