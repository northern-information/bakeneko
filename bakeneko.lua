-- k1: exit  e1: bpm
--
--
--      e2: signature   e3: length
--
--    k2: play      k3: reroll

configuration = {
  default_tempo = 120,
  -- change to whatever directory you want
  sample_directory = "/home/we/dust/audio/common/808",
  -- divisions can be 1, 2, 4, 8, 16 or 0 for "off"
  drum_1_division  = 8,
  -- set a file name or "random"
  drum_1_sample    = "808-BD.wav",
  drum_2_division  = 8,
  drum_2_sample    = "random",
  drum_3_division  = 4,
  drum_3_sample    = "random",
  drum_4_division  = 4,
  drum_4_sample    = "random",
  drum_5_division  = 1,
  drum_5_sample    = "random",
  drum_6_division  = 16,
  drum_6_sample    = "random",
}

function init()
  -- graphics
  is_screen_dirty = true
  bakeneko_frame = 4
  -- music
  is_playing = true
  count = 4
  quantum = 4
  signature_key = 4
  length = 1
  step = length * count -- start at the end so play starts on 1
  tempo = configuration.default_tempo
  transport = 0
  ppqn = 96
  patterns = {}
  -- stuff
  sound_loop_id = clock.run(sound_loop)
  graphics_loop_id = clock.run(graphics_loop)
  screen.aa(0)
  reroll()
  -- quarter notes
  -- patterns[1].pattern = { true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false }
  -- patterns[2].pattern = { true, false, true, false, true, false, true, false, true, false, true, false, true, false, true, false }
end


-- music


function sound_loop()
  while true do
    clock.sync(1 / ppqn)
    transport = transport + 1
    if is_playing then

      if transport % ppqn == 1 then
        step = wrap(step + 1, 1, length * count)
        bakeneko_frame = wrap((step % count), 1, 4)
        play_drums()
        update_screen()
      end

    end
    check_tempo()
  end
end


function play_drums()
  for i = 1, 6 do
    if not patterns[i].is_on then return end
    if patterns[i].pattern[step] then
      -- print(patterns[i].sample)
    end
  end
end

function make_pattern(i)
  local this_pattern = {}
  local this_division = get_drum_division(i)
  this_pattern["sample"] = get_drum_sample(i)
  this_pattern["divsion"] = this_division
  this_pattern["pattern"] = get_random_pattern(this_division)
  this_pattern["is_on"] = get_drum_division(i) ~= 0
  return this_pattern
end

function get_drum_sample(i)
  local sample = configuration["drum_" .. i .. "_sample"]
  if sample == "random" then
    return get_random_sample()
  else
    return configuration.sample_directory .. "/" .. sample
  end
end

function get_drum_division(i)
  return configuration["drum_" .. i .. "_division"]
end

function get_random_pattern(division)
  if division == 0 then return {} end
  local p = {}
  for i = 1, length * count do
    p[i] = math.random(0, 1) == 1
  end
  return p
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

-- user interactions


function key(k, z)
  if z == 0 then return
  elseif k == 2 then toggle()
  elseif k == 3 then reroll() end
  update_screen()
end

function toggle()
  is_playing = not is_playing
end

function reroll()
  for i = 1, 6 do
    patterns[i] = make_pattern(i)
  end
end

function enc(e, d)
      if e == 1 then update_tempo(d)
  elseif e == 2 then update_signature(d)
  elseif e == 3 then update_length(d)
  end
  update_screen()
end

function update_tempo(d)
  tempo = util.clamp((tempo + d), 20, 300)
end

function update_signature(d)
  signature_key = util.clamp(signature_key + d, 1, 32)
  quantum = signature_key < 17 and 4 or 8
  count = util.clamp(wrap(signature_key, 1, 16) + d, 1, 16)
  reroll()
end

function update_length(d)
  length = util.clamp(length + d, 1, 4)
end

-- graphics


function redraw()
  screen.clear()
  draw_patterns()
  draw_step()
  draw_grid()
  draw_time_signature()
  draw_bpm()
  draw_bakeneko()
  screen.update()
end

function graphics_loop()
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

function draw_grid()
  screen.level(15)
  screen.move(1, 1)   screen.line_rel(128, 0) screen.stroke()
  screen.move(1, 0)   screen.line_rel(0, 64)  screen.stroke()
  screen.move(1, 64)  screen.line_rel(128, 0) screen.stroke()
  screen.move(128, 0) screen.line_rel(0, 64)  screen.stroke()
  screen.move(36, 1)  screen.line_rel(0, 64)  screen.stroke()
  screen.move(4, 32)  screen.line_rel(28, 0)  screen.stroke()
  screen.move(36, 32) screen.line_rel(92, 0)  screen.stroke()
end

function draw_time_signature()
  local size = 24
  local x, y = 16, 26
  screen.level(15)
  screen.font_size(size)
  screen.font_face(3)
  screen.move(x, y)
  screen.text_center(count)
  screen.move(x, y + size + 4)
  screen.text_center(quantum)
end

function draw_bpm()
  local size = 24
  local x, y = 48, 25
  screen.level(15)
  screen.font_size(size)
  screen.font_face(3)
  screen.move(80, y)
  screen.text_right(tempo)
  screen.font_size(12)
  screen.move(85, y)
  screen.text("bpm " .. step)
  local sources = {}
  sources[1] = "internal"
  sources[2] = "midi"
  sources[3] = "link"
  sources[4] = "crow"
  screen.font_face(0)
  screen.font_size(8)
  screen.move(85, y - 12)
  screen.text(string.upper(sources[params:get("clock_source")]))
end

function draw_step()
  screen.level(15)
  screen.move(40 + (step * 4) - 1, 62)
  screen.line_rel(0, -11)
  screen.stroke()
end

function draw_patterns()
  for i = 1, 6 do
    ii = 0
    for k, v in pairs(patterns[i].pattern) do
      local level = v and 1 or 0
      level = ((step == ii + 1) and level == 1) and 15 or level
      screen.level(level)
      screen.move(40 + (ii * 4) + 1, 50 + (i * 2))
      screen.line_rel(3, 0)
      screen.stroke()
      ii = ii + 1
    end
  end
end

function draw_bakeneko()
  local frames = {}
  frames[1] = "<(=^,^=<)"
  frames[2] = "<(=^,^=)>"
  frames[3] = "(>=^,^=)>"
  frames[4] = "(^=^,^=)^"
  screen.level(15)
  screen.font_size(12)
  screen.font_face(3)
  screen.move(82, 45)
  screen.text_center(frames[bakeneko_frame])
end


-- stuff


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

function check_tempo()
  if tempo ~= params:get("clock_tempo") then
    params:set("clock_tempo", tempo)
  end
end

function update_screen()
  is_screen_dirty = true
end

function cleanup()
  clock.cancel(clock_id)
end

function rerun()
  norns.script.load(norns.state.script)
end