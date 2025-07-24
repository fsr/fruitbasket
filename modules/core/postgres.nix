{ ... }:
{
  # automatically back up all databases
  services.postgresqlBackup = {
    enable = true;
    location = "/var/lib/backup/postgresql";
    databases = [
      "course-management"
      "git"
      "grafana"
      "hedgedoc"
      "matrix-synapse"
      "mautrix-telegram"
      "mediawiki"
      "nextcloud"
      "postgres"
      "sogo"
      "vaultwarden"
      "mailman"
      "mailman-web"
    ];
  };

  services.postgresql.settings.max_connections = 1000;
}
