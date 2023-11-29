{ pkgs, ... }:
{
  # automatically back up all databases
  services.postgresqlBackup = {
    enable = true;
    location = "/var/lib/backup/postgresql";
    databases = [
      "course-management"
      "gitea"
      "hedgedoc"
      "matrix-synapse"
      "mautrix-telegram"
      "mediawiki"
      "nextcloud"
      "postgres"
      "sogo"
      "vaultwarden"
      "mailman"
      "mailmanweb"
      "zammad"
    ];
  };

  services.postgresql.settings.max_connections = 1000;
}
