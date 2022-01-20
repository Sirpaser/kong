return {
    postgres = {
      up = [[
        CREATE TABLE IF NOT EXISTS "vaults" (
          "id"           UUID     PRIMARY KEY,
          "ws_id"        UUID     REFERENCES "workspaces" ("id"),
          "prefix"       TEXT     UNIQUE,
          "name"         TEXT     NOT NULL,
          "description"  TEXT,
          "config"       JSONB    NOT NULL,
          "tags"         TEXT[],
          UNIQUE ("id", "ws_id"),
          UNIQUE ("prefix", "ws_id")
        );

        DROP TRIGGER IF EXISTS "vaults_sync_tags_trigger" ON "vaults";

        DO $$
        BEGIN
          CREATE INDEX IF NOT EXISTS "vaults_tags_idx" ON "vaults" USING GIN ("tags");
        EXCEPTION WHEN UNDEFINED_COLUMN THEN
          -- Do nothing, accept existing state
        END$$;

        DO $$
        BEGIN
          CREATE TRIGGER "vaults_sync_tags_trigger"
          AFTER INSERT OR UPDATE OF "tags" OR DELETE ON "vaults"
          FOR EACH ROW
          EXECUTE PROCEDURE sync_tags();
        EXCEPTION WHEN UNDEFINED_COLUMN OR UNDEFINED_TABLE THEN
          -- Do nothing, accept existing state
        END$$;
      ]]
    },

    cassandra = {
      up = [[
        CREATE TABLE IF NOT EXISTS vaults (
          id          uuid,
          ws_id       uuid,
          prefix      text,
          name        text,
          description text,
          config      text,
          tags        set<text>,
          PRIMARY KEY (id)
        );
        CREATE INDEX IF NOT EXISTS vaults_prefix_idx ON vaults (prefix);
        CREATE INDEX IF NOT EXISTS vaults_ws_id_idx  ON vaults (ws_id);
      ]]
    },
  }
