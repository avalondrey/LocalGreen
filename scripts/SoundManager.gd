extends Node
class_name SoundManager

# ─── Système de sons et musique procéduraux ──────────────────────────
enum SoundType { PLANT, WATER, HARVEST, GROWTH, COIN, CLICK, ACHIEVEMENT, QUEST, WEATHER, MUSIC }

var music_enabled: bool = true
var sfx_enabled: bool = true
var music_volume: float = 0.3
var sfx_volume: float = 0.5
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
        print("🔊 SoundManager initialisé")
        _setup_players()

func _setup_players() -> void:
        music_player = AudioStreamPlayer.new()
        music_player.volume_db = linear_to_db(music_volume)
        music_player.autoplay = true; add_child(music_player)
        sfx_player = AudioStreamPlayer.new()
        sfx_player.volume_db = linear_to_db(sfx_volume)
        add_child(sfx_player)
        _play_ambient_music()

func _play_ambient_music() -> void:
        var sample_rate = 22050
        var duration = 8.0
        var num_samples = int(sample_rate * duration)
        var data = PackedByteArray(); data.resize(num_samples * 2)
        for i in range(num_samples):
                var t = float(i) / float(sample_rate)
                var sample = 0.0
                sample += sin(TAU * 261.63 * t) * 0.08
                sample += sin(TAU * 392.0 * t) * 0.05
                sample += sin(TAU * 329.63 * t) * 0.04
                sample *= 0.6 + 0.4 * sin(TAU * 0.25 * t)
                sample = clampf(sample, -1.0, 1.0)
                data.encode_u16(i * 2, int(sample * 32767.0))
        var format = AudioStreamWAV.new()
        format.format = AudioStreamWAV.FORMAT_16_BITS
        format.mix_rate = sample_rate; format.stereo = false
        format.data = data
        format.loop_mode = AudioStreamWAV.LOOP_FORWARD
        format.loop_begin = 0; format.loop_end = num_samples
        music_player.stream = format; music_player.play()

func play_sound(type: SoundType) -> void:
        if not sfx_enabled: return
        var sample_rate = 22050
        var duration := 0.3
        var frequency := 440.0
        var decay := 5.0
        var wave_type := "sine"
        match type:
                SoundType.PLANT: duration = 0.2; frequency = 330.0; decay = 8.0
                SoundType.WATER: duration = 0.4; frequency = 800.0; decay = 6.0; wave_type = "noise"
                SoundType.HARVEST: duration = 0.35; frequency = 523.0; decay = 4.0
                SoundType.GROWTH: duration = 0.25; frequency = 440.0; decay = 7.0
                SoundType.COIN: duration = 0.15; frequency = 880.0; decay = 10.0
                SoundType.CLICK: duration = 0.08; frequency = 600.0; decay = 15.0
                SoundType.ACHIEVEMENT: duration = 0.6; frequency = 523.0; decay = 3.0
                SoundType.QUEST: duration = 0.5; frequency = 440.0; decay = 4.0
                SoundType.WEATHER: duration = 0.3; frequency = 200.0; decay = 5.0; wave_type = "noise"
                SoundType.MUSIC: return
        var num_samples = int(sample_rate * duration)
        var data = PackedByteArray(); data.resize(num_samples * 2)
        for i in range(num_samples):
                var t = float(i) / float(sample_rate)
                var envelope = exp(-decay * t)
                var sample: float
                if wave_type == "noise":
                        sample = (randf() * 2.0 - 1.0) * envelope * 0.3
                        if i > 0:
                                var prev = float(data.decode_s16((i - 1) * 2)) / 32767.0
                                sample = lerp(prev, sample, 0.3)
                else:
                        sample = sin(TAU * frequency * t) * envelope * 0.4
                        if type == SoundType.ACHIEVEMENT:
                                sample += sin(TAU * frequency * 1.5 * t) * envelope * 0.2
                                sample += sin(TAU * frequency * 2.0 * t) * envelope * 0.1
                if type == SoundType.COIN: frequency = lerp(880.0, 1320.0, t / duration)
                if type == SoundType.ACHIEVEMENT and t < 0.15:
                        sample += sin(TAU * 659.25 * t) * (1.0 - t / 0.15) * 0.3
                sample = clampf(sample, -1.0, 1.0)
                data.encode_s16(i * 2, int(sample * 32767.0))
        var format = AudioStreamWAV.new()
        format.format = AudioStreamWAV.FORMAT_16_BITS
        format.mix_rate = sample_rate; format.stereo = false; format.data = data
        sfx_player.stream = format; sfx_player.play()

func toggle_music() -> void:
        music_enabled = !music_enabled
        if music_player:
                if music_enabled:
                        music_player.play()
                else:
                        music_player.stop()

func toggle_sfx() -> void:
        sfx_enabled = !sfx_enabled

func set_music_volume(vol: float) -> void:
        music_volume = clampf(vol, 0.0, 1.0)
        if music_player: music_player.volume_db = linear_to_db(music_volume)

func set_sfx_volume(vol: float) -> void:
        sfx_volume = clampf(vol, 0.0, 1.0)
        if sfx_player: sfx_player.volume_db = linear_to_db(sfx_volume)
