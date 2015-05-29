-- Look for models in the same directory as this file.
require("getScriptFilename")
fn = getScriptFilename()
assert(fn, "Have to load this from file, not copy and paste, or we can't find our models!")
vrjLua.appendToModelSearchPath(fn)

colWavPath = vrjLua.findInModelSearchPath("sound/piuf.wav")

passWavPath = vrjLua.findInModelSearchPath("sound/bouit.wav")

if runbuf["local"] then
--OpenAL allows us to spatialize the sound
snx.changeAPI("OpenAL")

--create a sound info object
colSoundInfo = snx.SoundInfo()
passSoundInfo = snx.SoundInfo()

-- set the filename attribute of the soundFile
colSoundInfo.filename = colWavPath
passSoundInfo.filename = passWavPath

--create a new sound handle and pass it the filename from the soundInfo object
colSoundHandle = snx.SoundHandle(colSoundInfo.filename)
passSoundHandle = snx.SoundHandle(passSoundInfo.filename)
--configure the soundHandle to use the soundInfo
colSoundHandle:configure(colSoundInfo)
passSoundHandle:configure(passSoundInfo)
end

-- pos 3-slot array with the position to play the collision sound, by default it's the origin
function playCollisionSound( pos )
  if runbuf["local"] then
    pos = pos or {0,0,0}
    if colSoundHandle.isPlaying then
      colSoundHandle:stop()
    end
    --colSoundHandle.position = pos
    colSoundHandle:trigger(1)
  end
end

-- pos 3-slot array with the position to play the collision sound, by default it's the origin
function playPassSound( pos )
  if runbuf["local"] then
    pos = pos or {0,0,0}
    if passSoundHandle.isPlaying then
      passSoundHandle:stop()
    end
    --passSoundHandle.position = pos
    passSoundHandle:trigger(1)
  end
end
