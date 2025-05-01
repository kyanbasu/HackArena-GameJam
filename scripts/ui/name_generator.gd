@tool
extends Node

var adjectives : Array = [
    "Abyssal", "Aerospace", "Aetherial", "Arcane", "Astral", 
    "Astronomical", "Astronomical", "Brilliant", "Brilliant", "Celestial", 
    "Celestial", "Cosmic", "Cosmic", "Cryptic", "Dazzling", 
    "Diaphanous", "Divine", "Dreamlike", "Effulgent", "Elliptical", 
    "Empyrean", "Enigmatic", "Esoteric", "Ethereal", "Extraterrestrial", 
    "Galactic", "Galactic", "Gemlike", "Glittering", "Haloed", 
    "Heavenly", "Incandescent", "Infinite", "Inscrutable", "Insidious", 
    "Intergalactic", "Interplanetary", "Interstellar", "Iridescent", "Lucent", 
    "Luminescent", "Luminous", "Lustrous", "Macabre", "Miraculous", 
    "Murky", "Mystic", "Mystical", "Nebular", "Nebulous", 
    "Nocturnal", "Numinous", "Obscure", "Occult", "Ominous", 
    "Opaline", "Orbital", "Otherworldly", "Phantasmagoric", "Phosphorescent", 
    "Quantum", "Radiant", "Relativistic", "Resplendent", "Serene", 
    "Shadowy", "Shimmering", "Shining", "Sidereal", "Spaceborne", 
    "Spacefaring", "Sparkling", "Spectral", "Stellar", "Stelliferous", 
    "Stygian", "Sublime", "Suborbital", "Tenebrous", "Theoretical", 
    "Titanic", "Transcendent", "Umbrous", "Unbounded", "Unfathomable", 
    "Universal", "Vast", "Weightless", 
]

var nouns : Array = [
    "Aldebaran", "Altair", "Andromeda", "Antares", "Aphelion", 
    "Apogee", "Apollo", "Aquarius", "Ara", "Artemis", 
    "Atlas", "Aurora", "Betelgeuse", "Black Hole", "Boson", 
    "Cassini", "Cassiopeia", "Cepheus", "Ceres", "Challenger", 
    "Columbia", "Comet", "Corona", "Cronus", "Cygnus", 
    "Deneb", "Discovery", "Draco", "Eclipse", "Endeavour", 
    "Enterprise", "Eos", "Equinox", "Eris", "Event Horizon", 
    "Gaia", "Gemini", "Gluon", "Gravity", "Hadron", 
    "Haumea", "Helios", "Horizon", "Hydra", "Hyperion", 
    "Jupiter", "Leo", "Lepton", "Luna", "Lyra", 
    "Makemake", "Mars", "Mercury", "Meteor", "Muon", 
    "Nadir", "Neptune", "Neutrino", "Nova", "Odyssey", 
    "Orion", "Pathfinder", "Pegasus", "Perigee", "Perihelion", 
    "Perseus", "Phoenix", "Photon", "Pioneer", "Pluto", 
    "Polaris", "Procyon", "Prometheus", "Pulsar", "Quark", 
    "Quasar", "Radiance", "Rhea", "Rigel", "Sagitta", 
    "Saturn", "Scorpius", "Selene", "Singularity", "Sirius", 
    "Solstice", "Spica", "Stella", "Supernova", "Tachyon", 
    "Taurus", "Themis", "Titan", "Ursa Major", "Ursa Minor", 
    "Vega", "Venus", "Virgo", "Voyager", "Zenith", 
]

# Keeping all adjectives and nouns sorted
func _ready() -> void:
    # Only prints if game started with print-names parameter
    if !Array(OS.get_cmdline_args()).has("print-names"): return
    var a = "    "
    adjectives.sort()
    var i = 0
    for ad in adjectives:
        a += '"%s", ' % ad.capitalize()
        if i%5 == 4:
            a += "\n    "
        i += 1
    
    var n = "    "
    nouns.sort()
    i = 0
    for no in nouns:
        n += '"%s", ' % no.capitalize()
        if i%5 == 4:
            n += "\n    "
        i += 1
    
    print("Adjectives:")
    print(a)
    print("Nouns:")
    print(n)

func get_random_name() -> String:
    return "%s %s" % [adjectives.pick_random().capitalize(), nouns.pick_random().capitalize()]
    
