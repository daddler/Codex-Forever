--------------------------------------------------
-- WeintCodex :: Spezialisierungen von Forever
--
-- NEUN KLASSEN, JE DREI TALENTBÄUME. Diese Tabelle ist - anders als
-- data/raids.lua - KEINE Vermutung und deshalb gefüllt: die Namen
-- stehen seit der ersten Fassung des Spiels fest, und die Ankündigung
-- nennt eine Überarbeitung der Bäume, keine neuen. Was Forever an
-- ihnen ändert (welches Talent wo sitzt, was es tut), steht hier
-- ausdrücklich NICHT.
--
-- Sie ist die Spiegelung von `analyzer/data/specs.py` der Companion.
-- Laufen die beiden auseinander, ist das Symptom eine Zeile, die leer
-- bleibt, ohne dass irgendwo etwas fehlschlägt - deshalb dieselben
-- Schreibweisen, dieselbe Reihenfolge, dieselben Rollen.
--
-- DER EINE BAUM OHNE ROLLE: "Wilder Kampf" des Druiden ist in dieser
-- Fassung des Spiels BEIDE Rollen - dieselben Talente tragen Katze und
-- Bär, und welche davon jemand gerade ist, entscheidet die Gestalt und
-- nicht der Baum. Er trägt deshalb `nil` als Rolle und nicht "dps".
-- Das ist keine Lücke, sondern die richtige Antwort.
--
-- Der Schlüssel (`key`) ist die Form, in der die Spezialisierung über
-- die Companion-Brücke geht: `CLASSFILE_ENGLISCHERBAUM`, versal und
-- ohne Leerzeichen.
--------------------------------------------------

WeintCodex_Specs = {

    { class = "DRUID",   name = "Gleichgewicht",     english = "Balance",       role = "dps"    },
    { class = "DRUID",   name = "Wilder Kampf",      english = "Feral",         role = nil      },
    { class = "DRUID",   name = "Wiederherstellung", english = "Restoration",   role = "healer" },

    { class = "HUNTER",  name = "Tierherrschaft",    english = "Beast Mastery", role = "dps"    },
    { class = "HUNTER",  name = "Treffsicherheit",   english = "Marksmanship",  role = "dps"    },
    { class = "HUNTER",  name = "Überleben",         english = "Survival",      role = "dps"    },

    { class = "MAGE",    name = "Arkan",             english = "Arcane",        role = "dps"    },
    { class = "MAGE",    name = "Feuer",             english = "Fire",          role = "dps"    },
    { class = "MAGE",    name = "Frost",             english = "Frost",         role = "dps"    },

    { class = "PALADIN", name = "Heilig",            english = "Holy",          role = "healer" },
    { class = "PALADIN", name = "Schutz",            english = "Protection",    role = "tank"   },
    { class = "PALADIN", name = "Vergeltung",        english = "Retribution",   role = "dps"    },

    { class = "PRIEST",  name = "Disziplin",         english = "Discipline",    role = "healer" },
    { class = "PRIEST",  name = "Heilig",            english = "Holy",          role = "healer" },
    { class = "PRIEST",  name = "Schatten",          english = "Shadow",        role = "dps"    },

    { class = "ROGUE",   name = "Meucheln",          english = "Assassination", role = "dps"    },
    { class = "ROGUE",   name = "Kampf",             english = "Combat",        role = "dps"    },
    { class = "ROGUE",   name = "Täuschung",         english = "Subtlety",      role = "dps"    },

    { class = "SHAMAN",  name = "Elementar",         english = "Elemental",     role = "dps"    },
    { class = "SHAMAN",  name = "Verstärkung",       english = "Enhancement",   role = "dps"    },
    { class = "SHAMAN",  name = "Wiederherstellung", english = "Restoration",   role = "healer" },

    { class = "WARLOCK", name = "Gebrechen",         english = "Affliction",    role = "dps"    },
    { class = "WARLOCK", name = "Dämonologie",       english = "Demonology",    role = "dps"    },
    { class = "WARLOCK", name = "Zerstörung",        english = "Destruction",   role = "dps"    },

    { class = "WARRIOR", name = "Waffen",            english = "Arms",          role = "dps"    },
    { class = "WARRIOR", name = "Furor",             english = "Fury",          role = "dps"    },
    { class = "WARRIOR", name = "Schutz",            english = "Protection",    role = "tank"   },

}

--------------------------------------------------
-- Zugriff
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Specs = {}

-- Schlüssel einer Spezialisierung: CLASSFILE_ENGLISCHERBAUM, versal
-- und ohne Leerzeichen. "Beast Mastery" wird damit zu
-- HUNTER_BEASTMASTERY.
function WeintCodex.Specs.Key(spec)
    if type(spec) ~= "table" then return nil end
    return spec.class .. "_" .. (spec.english:gsub("%s+", ""):upper())
end

-- Die drei Bäume einer Klasse, in Baumreihenfolge. Eine unbekannte
-- Klasse liefert eine leere Liste - nicht nil, weil der Aufrufer
-- darüber iteriert.
function WeintCodex.Specs.ForClass(classFile)
    local out = {}
    if type(classFile) ~= "string" then return out end
    for _, spec in ipairs(WeintCodex_Specs) do
        if spec.class == classFile then
            out[#out + 1] = spec
        end
    end
    return out
end

-- Baum `index` (1..3) einer Klasse. `nil`, wenn es ihn nicht gibt -
-- der Client kann einen Index liefern, den diese Tabelle nicht kennt,
-- und dann ist "unbekannt" die einzige ehrliche Antwort.
function WeintCodex.Specs.ByIndex(classFile, index)
    if type(index) ~= "number" then return nil end
    local list = WeintCodex.Specs.ForClass(classFile)
    return list[index]
end

-- Nach deutschem oder englischem Namen suchen, innerhalb einer Klasse.
function WeintCodex.Specs.ByName(classFile, name)
    if type(name) ~= "string" or name == "" then return nil end
    local lower = (strlower or string.lower)(name)
    for _, spec in ipairs(WeintCodex.Specs.ForClass(classFile)) do
        if (strlower or string.lower)(spec.name) == lower
            or (strlower or string.lower)(spec.english) == lower then
            return spec
        end
    end
    return nil
end
