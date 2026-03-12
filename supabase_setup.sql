-- Supabase SQL für FilamentTracker

-- Tabelle: filamente
CREATE TABLE IF NOT EXISTS filamente (
  id TEXT PRIMARY KEY,
  marke TEXT NOT NULL,
  typ TEXT NOT NULL,
  farbe TEXT NOT NULL,
  gewicht_gramm INTEGER NOT NULL,
  restgewicht_gramm INTEGER NOT NULL,
  preis DOUBLE PRECISION DEFAULT 0,
  gekauft_am TIMESTAMP WITH TIME ZONE NOT NULL,
  herkunftsland TEXT,
  bemerkung TEXT,
  user_id UUID NOT NULL
);

-- Tabelle: verbrauch
CREATE TABLE IF NOT EXISTS verbrauch (
  id TEXT PRIMARY KEY,
  filament_id TEXT NOT NULL,
  verbraucht_gramm INTEGER NOT NULL,
  datum TIMESTAMP WITH TIME ZONE NOT NULL,
  projekt_name TEXT,
  user_id UUID NOT NULL
);

-- Row Level Security (RLS) - nur eigene Daten sichtbar
ALTER TABLE filamente ENABLE ROW LEVEL SECURITY;
ALTER TABLE verbrauch ENABLE ROW LEVEL SECURITY;

-- Policy: User darf nur eigene Filamente sehen
DROP POLICY IF EXISTS "Users can see own filamente" ON filamente;
CREATE POLICY "Users can see own filamente" ON filamente
  FOR ALL USING (auth.uid() = user_id);

-- Policy: User darf nur eigenen Verbrauch sehen
DROP POLICY IF EXISTS "Users can see own verbrauch" ON verbrauch;
CREATE POLICY "Users can see own verbrauch" ON verbrauch
  FOR ALL USING (auth.uid() = user_id);

-- Index für bessere Performance
DROP INDEX IF EXISTS idx_filamente_user_id;
DROP INDEX IF EXISTS idx_verbrauch_user_id;
DROP INDEX IF EXISTS idx_verbrauch_filament_id;

CREATE INDEX idx_filamente_user_id ON filamente(user_id);
CREATE INDEX idx_verbrauch_user_id ON verbrauch(user_id);
CREATE INDEX idx_verbrauch_filament_id ON verbrauch(filament_id);
