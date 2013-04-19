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

  -- print(table.show(urls))

  return urls
end


