-- k1: exit  e1: --
--
--
--      e2: bpm       e3: level
--
--    k2: play      k3: reroll

configuration = {
  start_playing_on_boot = true, -- start playing as soon as you launch the script?
  default_bpm = 120, -- change with e2 while running
  default_level = 100, -- how loud is the whole thing
  sample_directory = "/home/we/dust/audio/common/808",  -- change to whatever directory you want

  track_1_on = true, -- toggle the sample on and off
  track_1_level = 100, -- max level of this sample
  track_1_density = 50, -- percentage representing how dense the notes are if randomized pattern is used
  track_1_period  = 1/16, -- periods can be anything (i think)
  track_1_haunted_fraction = 1/16, -- ghost
  track_1_length = 16, -- how many periods before looping back to 1?
  track_1_sample = "808-BD.wav", -- specifcy a sample name
  track_1_pattern = "x---x---x---x---", -- draw a pattern with "x" and "-"

  track_2_on = "random",
  track_2_level = "random",
  track_2_density = "random",
  track_2_period = "random",
  track_2_haunted_fraction = "random",
  track_2_length = "random",
  track_2_sample = "random",
  track_2_pattern = "random",
  
  track_3_on = true,  
  track_3_level = 100,
  track_3_density = 50, 
  track_3_period = 1/4,
  track_3_haunted_fraction = 1/2,
  track_3_length = 8,
  track_3_sample = "random",
  track_3_pattern = "random",
  
  track_4_on = true,  
  track_4_level = 50,
  track_4_density = 50,
  track_4_period = 1/8,
  track_4_haunted_fraction = 1/3,
  track_4_length = 16,
  track_4_sample = "random",
  track_4_pattern = "random",
  
  track_5_on = true,  
  track_5_level = 50,
  track_5_density = 50, 
  track_5_period = 1,
  track_5_haunted_fraction = 1/4,
  track_5_length = "random",
  track_5_sample = "random",
  track_5_pattern = "random",
  
  track_6_on = true,  
  track_6_level = 25,
  track_6_density = 100,
  track_6_period = 1/8,
  track_6_haunted_fraction = 1,
  track_6_length = 4,
  track_6_sample = "random",
  track_6_pattern = "random",
}

engine.name = "Goldeneye"
lattice = require("lattice")

function init()
  -- draw
  screen.aa(0)
  is_screen_dirty = true
  bakeneko_frame = 4
  -- music
  is_playing = configuration.start_playing_on_boot
  bpm = configuration.default_bpm
  level = configuration.default_level
  numerator = 0
  denominator = 4
  transport = 0
  tracks = {}
  clock_sources = { "internal", "midi", "link", "crow" }
  -- time
  draw_loop_id = clock.run(draw_loop)
  bakeneko_lattice = lattice:new()
  bakeneko_lattice:new_pattern{
    action = function(t) dance() end,
    division = 1,
    enabled = true
  }
  bakeneko_lattice:start()
  reroll()
end

function dance()
  if is_playing then
    numerator = util.wrap(numerator + 1, 1, denominator)
    bakeneko_frame = util.wrap(bakeneko_frame + 1, 1, 4)
    update_screen()
    check_bpm()
    check_screen()
  end
end


function key(k, z)
  if z == 0 then return
  elseif k == 2 then toggle()
  elseif k == 3 then reroll() end
  update_screen()
end

function enc(e, d)
      if e == 1 then -- nothing
  elseif e == 2 then update_bpm(d)
  elseif e == 3 then update_level(d)
  end
  update_screen()
end

function toggle()
  is_playing = not is_playing
end

function update_level(d)
  level = util.clamp(level + d, 0, 100)
end

function update_bpm(d)
  bpm = util.clamp((bpm + d), 20, 300)
end

function check_bpm()
  if bpm ~= params:get("clock_tempo") then
    params:set("clock_tempo", bpm)
  end
end

function update_screen()
  is_screen_dirty = true
end

-- sample stuff

function reroll()
  for i = 1, 6 do
    tracks[i] = make_track(i)
    bakeneko_lattice:new_pattern{
      action = function(t) event(i) end,
      division = tracks[i].haunted_fraction,
      enabled = tracks[i].on
    }
  end
end

function event(i)
  if is_playing then
    local track = tracks[i]
    if not track.on then return end
    track.current_step = util.wrap(track.current_step + 1, 1, track.length)
    if track.pattern[track.current_step] then
      engine.play(track.sample, track.level / 100, 0, 0, 1, 0, 1, 1)
    end
    update_screen()
  end
end

function make_track(i)
  local this_track = {}
  this_track["on"] = get_on(configuration["track_" .. i .. "_on"])
  this_track["sample"] = get_track_sample(configuration["track_" .. i .. "_sample"])
  this_track["period"] = get_period(configuration["track_" .. i .. "_period"])
  this_track["haunted_fraction"] = get_haunted_fraction(configuration["track_" .. i .. "_haunted_fraction"])
  this_track["level"] = get_level(configuration["track_" .. i .. "_level"])
  this_track["length"] = get_length(configuration["track_" .. i .. "_length"])
  this_track["density"] = get_density(configuration["track_" .. i .. "_density"])
  this_track["pattern"] = get_pattern(configuration["track_" .. i .. "_pattern"], this_track.density, this_track.length)
  this_track["current_step"] = 0
  return this_track
end

function get_on(on)
  if on == "random" then
    return math.random(0, 1) == 1
  else
    return on
  end
end

function get_track_sample(sample)
  if sample == "random" then
    return get_random_sample()
  else
    return configuration.sample_directory .. "/" .. sample
  end
end

function get_random_sample()
  local i, t, popen = 0, {}, io.popen
  local pfile = popen('ls -a "' .. configuration.sample_directory .. '"')
  for filename in pfile:lines() do
    if filename ~= "." and filename ~= ".." then
      i = i + 1
      t[i] = filename
    end
  end
  pfile:close()
  return configuration.sample_directory .. "/" .. t[math.random(1, #t)]
end

function get_period(period)
  if period == "random" then
    return math.random(1, 16) / 16
  else
    return period
  end
end

function get_haunted_fraction(haunted_fraction)
  if haunted_fraction == "random" then
    return math.random(1, 16) / 16
  else
    return haunted_fraction
  end
end

function get_level(level)
  if level == "random" then
    return math.random(0, 100)
  else
    return level
  end
end

function get_length(length)
  if length == "random" then
    return math.random(1, 16)
  else
    return length
  end
end

function get_density(density)
  if density == "random" then
    return math.random(0, 100)
  else
    return density
  end
end

function get_pattern(pattern, density, length)
  local p = {}
  if pattern == "random" then
    for i = 1, length do
      p[i] = math.random(0, 100) < density
    end
  else
    for i = 1, #pattern do
      p[i] = pattern:sub(i, i) ~= '-'
    end    
  end
  return p
end


-- draw


function redraw()
  screen.clear()
  draw_tracks()
  draw_bpm()
  draw_bakeneko()
  screen.update()
end

function draw_loop()
  while true do
    check_screen()
    clock.sleep(1 / 30)
  end
end

function check_screen()
  if is_screen_dirty then
    redraw()
    is_screen_dirty = false
  end
end

function draw_tracks()
  for i = 1, 6 do
    ii = 0
    for k, v in pairs(tracks[i].pattern) do
      local level = v and 5 or 1
      local current_step = tracks[i].current_step == ii + 1
      level = (current_step and level == 5) and 15 or level
      level = tracks[i].on and level or 0
      screen.level(level)
      if current_step then
        screen.rect((i * 7) - 7, (ii * 4) + 1, 5, 3)
        screen.fill()
      else
        screen.rect((i * 7) - 5, 2 + (ii * 4), 2, 2)
        screen.stroke()
      end
      ii = ii + 1
    end
  end
end

function draw_bpm()
  local size = 24
  local x, y = 48, 25
  screen.level(15)
  screen.font_size(size)
  screen.font_face(3)
  screen.move(80, y)
  screen.text_right(bpm)
  screen.font_size(12)
  screen.move(85, y)
  screen.text("bpm")
  screen.font_face(0)
  screen.font_size(8)
  screen.move(85, y - 12)
  screen.text(string.upper(clock_sources[params:get("clock_source")]))
end

function draw_bakeneko()
  local frames = {}
  frames[1] = "<(=^,^=<)"
  frames[2] = "<(=^,^=)>"
  frames[3] = "(>=^,^=)>"
  frames[4] = "(^=^,^=)^"
  screen.level(15)
  screen.font_size(20)
  screen.font_face(3)
  screen.move(82, 54)
  screen.text_center(frames[bakeneko_frame])
end


-- utility functions


function rerun()
  norns.script.load(norns.state.script)
end

function r()
  rerun()
end