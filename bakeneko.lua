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

  track_1_on = true, -- toggle the drum on and off
  track_1_level = 100, -- max level of this drum
  track_1_density = 50, -- percentage representing how dense the notes are
  track_1_period  = 1/4, -- periods can be anything (i think)
  track_1_length = 16, -- how many periods before looping back to 1?
  track_1_sample = "808-BD.wav", -- specifcy a sample name
  track_1_pattern = "x---x---x---x---", -- draw a pattern with "x" and "-"

  track_2_on = "random", -- ...or spin the wheel with "randoms"
  track_2_level = "random",
  track_2_density = "random",
  track_2_period = "random",
  track_2_length = "random",
  track_2_sample = "random",
  track_2_pattern = "random",
  
  track_3_on = true,  
  track_3_level = 100,
  track_3_density = 50, 
  track_3_period = 1/4,
  track_3_length = 8,
  track_3_sample = "random",
  track_3_pattern = "random",
  
  track_4_on = true,  
  track_4_level = 50,
  track_4_density = 50,
  track_4_period = 1/8,
  track_4_length = 16,
  track_4_sample = "random",
  track_4_pattern = "random",
  
  track_5_on = true,  
  track_5_level = 50,
  track_5_density = 50, 
  track_5_period = 1,
  track_5_length = "random",
  track_5_sample = "random",
  track_5_pattern = "random",
  
  track_6_on = true,  
  track_6_level = 25,
  track_6_density = 100,
  track_6_period = 1/8,
  track_6_length = 4,
  track_6_sample = "random",
  track_6_pattern = "random",
}

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
  -- time
  softclock.init()
  softclock_loop_id = clock.run(softclock.super_tick)
  draw_loop_id = clock.run(draw_loop)
  -- go
  reroll()
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

function cleanup()
  clock.cancel(softclock_loop_id)
  clock.cancel(draw_loop_id)
end

-- sample stuff

function reroll()
  setup_sampler()
  for i = 1, 6 do
    tracks[i] = make_track(i)
    softcut.buffer_clear_region_channel(i, 0, -1)
    softcut.buffer_read_mono(tracks[i].sample, 0, 0, -1, 1, i)
    softclock:add(i, tracks[i].period, function(phase) event(i, phase) end)
  end
end

function event(i, phase)
  local track = tracks[i]
  if not track.on then return end
  track.current_step = wrap(track.current_step + 1, 1, track.length)
  if track.pattern[track.current_step] then
    play_sample(i)
  end
  update_screen()
end

function make_track(i)
  local this_track = {}
  this_track["on"] = get_on(configuration["track_" .. i .. "_on"])
  this_track["sample"] = get_track_sample(configuration["track_" .. i .. "_sample"])
  this_track["period"] = get_period(configuration["track_" .. i .. "_period"])
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

function setup_sampler()
  softcut.reset()
  softcut.buffer_clear()
  audio.level_cut(1)
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  for i = 1, 6 do
    softcut.level(i, 1)
    softcut.level_input_cut(1, i, 1.0)
    softcut.level_input_cut(2, i, 1.0)
    softcut.pan(i, 0)
    softcut.play(i, 0)
    softcut.rate(i, 1)
    softcut.loop_start(i, 0)
    softcut.loop_end(i, 36)
    softcut.loop(i, 0)
    softcut.rec(i, 0)
    softcut.fade_time(i, 0.02)
    softcut.level_slew_time(i, 0.01)
    softcut.rate_slew_time(i, 0.01)
    softcut.rec_level(i, 1)
    softcut.pre_level(i, 1)
    softcut.position(i, 0)
    softcut.buffer(i, 1)
    softcut.enable(i, 1)
    softcut.filter_dry(i, 1)
    softcut.filter_fc(i, 0)
    softcut.filter_lp(i, 0)
    softcut.filter_bp(i, 0)
    softcut.filter_rq(i, 0)
  end
end

function play_sample(i)
  softcut.buffer(i, 2)
  softcut.play(i, 0)
  softcut.level(i, (level / 100) * (tracks[i].level / 100))
  softcut.position(i, 0)
  softcut.loop_start(i, 0)
  softcut.loop_end(i, 16)
  softcut.loop(i, 0)
  softcut.play(i, 1)
end


-- softclock


softclock = {}

function softclock.init()
  softclock.super_period = 96
  softclock.transport = 0
  softclock.song_clocks = {}
  softclock.sources = {}
  softclock.sources[1] = "internal"
  softclock.sources[2] = "midi"
  softclock.sources[3] = "link"
  softclock.sources[4] = "crow"
end

function softclock.super_tick()
  while true do
    clock.sync(1 / softclock.super_period)
    softclock.transport = softclock.transport + 1
    if is_playing then
      if softclock.transport % softclock.super_period == 1 then
        numerator = wrap(numerator + 1, 1, denominator)
        bakeneko_frame = wrap(bakeneko_frame + 1, 1, 4)
        update_screen()
      end
      for id, song_clock in pairs(softclock.song_clocks) do
        song_clock.phase_ticks = song_clock.phase_ticks + 1
        if song_clock.phase_ticks > song_clock.period_ticks then
          song_clock.phase_ticks = song_clock.phase_ticks - song_clock.period_ticks
          song_clock.event(song_clock.phase_ticks)
        end
      end
    end
    check_bpm()
    check_screen()
  end
end 

function softclock:add(id, period, event)
  local c = {}
  c.phase_ticks = 0
  c.period_ticks = period / (1 / self.super_period) * denominator
  c.event = event
  self.song_clocks[id] = c
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
  screen.text(string.upper(softclock.sources[params:get("clock_source")]))
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


function wrap(value, min, max)
  local y = value
  local d = max - min + 1
  while y > max do
    y = y - d
  end
  while y < min do
    y = y + d
  end
  return y
end

function table_contains(t, element)
  for _, value in pairs(t) do
    if value == element then
      return true
    end
  end
  return false
end

function rerun()
  norns.script.load(norns.state.script)
end