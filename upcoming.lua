dofile("table_show.lua")

local read_file = function(file)
  local f = io.open(file)
  local data = f:read("*all")
  f:close()
  return data
end

local url_count = 0

wget.callbacks.get_urls = function(file, url, is_css, iri)
  -- progress message
  url_count = url_count + 1
  if url_count % 10 == 0 then
    io.stdout:write("\r - Downloaded "..url_count.." URLs")
    io.stdout:flush()
  end

  local urls = {}

  -- WITHOUT TRAILING SLASH
  local event_id = string.match(url, "^http://upcoming%.yahoo%.com/event/([0-9]+)/.+/.+[^/]$")
  if event_id then
    -- again, now with trailing slash
    table.insert(urls, { url=("http://upcoming.yahoo.com/event/"..event_id.."/"), link_expect_html=1 })
  end
  local venue_id = string.match(url, "^http://upcoming%.yahoo%.com/venue/([0-9]+)/.+/.+[^/]$")
  if venue_id then
    -- again, now with trailing slash
    table.insert(urls, { url=("http://upcoming.yahoo.com/venue/"..venue_id.."/"), link_expect_html=1 })
  end

  -- EVENT
  local event_id = string.match(url, "^http://upcoming%.yahoo%.com/event/([0-9]+)/.+/.+/$")
  if event_id then
    table.insert(urls, { url=("http://upcoming.yahoo.com/ajax/event_page_all_attendees.php?event_id="..event_id) })
    table.insert(urls, { url=("http://upcoming.yahoo.com/ajax/additional_dates.php"), post_data=("event_id="..event_id) })

    local html = read_file(file)
    if string.match(html, "/photos/event/"..event_id) then
      table.insert(urls, { url=("http://upcoming.yahoo.com/photos/event/"..event_id), link_expect_html=1 })
    end
    if string.match(html, "/maps/event/"..event_id) then
      table.insert(urls, { url=("http://upcoming.yahoo.com/maps/event/"..event_id), link_expect_html=1 })
    end
  end

  -- EVENT PAGE ALL ATTENDEES
  local event_id = string.match(url, "^http://upcoming%.yahoo%.com/ajax/event_page_all_attendees%.php")
  if event_id then
    local html = read_file(file)
    for img in string.gmatch(html, "http://farm[^\"]+%.flickr%.com/[^\"]+%.jpg") do
      table.insert(urls, { url=(img) })
    end
  end

  -- EVENT PHOTOS INDEX
  local photos_base = string.match(url, "^http://upcoming%.yahoo%.com/photos/event/[0-9]+$")
  if photos_base then
    local html = read_file(file)
    for photo in string.gmatch(html, "/flickr/[0-9]+/event/[0-9]+") do
      table.insert(urls, { url=("http://upcoming.yahoo.com"..photo), link_expect_html=1 })
    end
  end

  -- VENUE
  local venue_base = string.match(url, "^(http://upcoming%.yahoo%.com/venue/[0-9]+/.+/.+/)$")
  if venue_base then
    table.insert(urls, { url=(venue_base.."?show=upcoming-only"), link_expect_html=1 })
    table.insert(urls, { url=(venue_base.."?show=past-only"), link_expect_html=1 })
  end

  -- GROUP
  local group_id = string.match(url, "^http://upcoming%.yahoo%.com/group/([0-9]+)/[^/]*$")
  if group_id then
    table.insert(urls, { url=("http://upcoming.yahoo.com/group/"..group_id.."/history/"), link_expect_html=1 })

    local html = read_file(file)
    for page_num in string.gmatch(html, "%?page=([0-9]+)") do
      table.insert(urls, { url=("http://upcoming.yahoo.com/group/"..group_id.."/?page="..page_num), link_expect_html=1 })
    end
    for topic_id in string.gmatch(html, "/group/topic/([0-9]+)/") do
      table.insert(urls, { url=("http://upcoming.yahoo.com/group/topic/"..topic_id.."/"), link_expect_html=1 })
    end
  end

  -- GROUP HISTORY
  local group_id = string.match(url, "^http://upcoming%.yahoo%.com/group/([0-9]+)/history/")
  if group_id then
    table.insert(urls, { url=("http://upcoming.yahoo.com/group/"..group_id.."/history/"), link_expect_html=1 })

    local html = read_file(file)
    for page_num in string.gmatch(html, "%?page=([0-9]+)") do
      table.insert(urls, { url=("http://upcoming.yahoo.com/group/"..group_id.."/history/?page="..page_num), link_expect_html=1 })
    end
  end

  -- GROUP DIRECTORY
  local group_id = string.match(url, "^http://upcoming%.yahoo%.com/group/directory/")
  if group_id then
    table.insert(urls, { url=("http://upcoming.yahoo.com/group/directory/?page=all"), link_expect_html=1 })

    local html = read_file(file)
    for page_num in string.gmatch(html, "%?page=([0-9]+)") do
      table.insert(urls, { url=("http://upcoming.yahoo.com/group/directory/?page="..page_num), link_expect_html=1 })
    end
  end

  -- USER
  local user_id = string.match(url, "^http://upcoming%.yahoo%.com/user/([0-9]+)/$")
  if user_id then
    table.insert(urls, { url=("http://upcoming.yahoo.com/user/"..user_id.."/past/"), link_expect_html=1 })
    table.insert(urls, { url=("http://upcoming.yahoo.com/ajax/user_page_all_events.php?user_id="..user_id.."&v=future") })
    table.insert(urls, { url=("http://upcoming.yahoo.com/ajax/user_page_all_events.php?user_id="..user_id.."&v=past") })
    table.insert(urls, { url=("http://upcoming.yahoo.com/ajax/user_artists.php"), post_data=("cmd=get&user_id="..user_id.."&offset=0&count=10000") })
    table.insert(urls, { url=("http://upcoming.yahoo.com/ajax/user_venue.php"), post_data=("cmd=get&user_id="..user_id.."&count=10000") })
  end

  -- print(table.show(urls))

  return urls
end


wget.callbacks.httploop_result = function(url, err, http_stat)
  if http_stat.statcode == 999 then
    -- try again
    io.stdout:write("\nYahoo rate limit (error 999). Waiting for 300 seconds...\n")
    io.stdout:flush()
    os.execute("sleep 300")
    return wget.actions.CONTINUE
  else
    return wget.actions.NOTHING
  end
end


