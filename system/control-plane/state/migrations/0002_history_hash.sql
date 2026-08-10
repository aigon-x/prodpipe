-- ============================================================================
-- MIGRATION 0002 — HISTORY HASH (F4: event/evidence integrity)
-- ============================================================================
-- F4: state_hash obejmuje WYŁĄCZNIE canonical operational state
-- (desired/effective/observed). event + evidence to append-only history
-- (engineering telemetry) — NIE są częścią stanu, ale MUSZĄ mieć własny
-- łańcuch integralności, aby manipulacja audytem była wykrywalna.
--
-- Dodaje kolumnę history_hash do snapshot, aby każdy snapshot rejestrował
-- BOTH: state_hash (stan) i history_hash (historia/audyt).
-- ============================================================================

ALTER TABLE snapshot ADD COLUMN history_hash TEXT;

-- Zaktualizuj wersję schematu
UPDATE meta SET value = '2' WHERE key = 'schema_version';
