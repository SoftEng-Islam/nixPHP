{ pkgs, lib, config, inputs, ... }:
let
  listen_port = 3312;
  server_name = "localhost";
in {
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [ pkgs.git pkgs.php ];

  # https://devenv.sh/languages/
  # Configure PHP
  languages.php.package = pkgs.php.buildEnv {
    extensions = ({ enabled, all }: enabled ++ (with all; [ yaml ]));
    extraConfig = ''
      sendmail_path = ${config.services.mailpit.package}/bin/mailpit sendmail
      smtp_port = 1025
      upload_max_filesize = 64M
      post_max_size = 64M
      max_execution_time = 300
    '';
  };
  languages.php.fpm.pools.web = {
    settings = {
      "clear_env" = "no";
      "pm" = "dynamic";
      "pm.max_children" = 10;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 10;
    };
  };
  languages.php.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # MySQL
  services.mysql = {
    enable = true;
    settings.mysqld.port = 3407;
    initialDatabases = [{ name = "nixPHP"; }];
    ensureUsers = [{
      name = "softeng";
      password = "1122";
      ensurePermissions = { "nixPHP.*" = "ALL PRIVILEGES"; };
    }];
  };

  # NGINX
  services.nginx = {
    enable = true;
    httpConfig = ''
      server {
        listen ${toString listen_port};
        root ${config.devenv.root}/src;
        index index.php index.html;
        server_name ${server_name};

        # ✅ Increase max upload size
        client_max_body_size 64M;

        # Rewrite rules
        if (!-e $request_filename) {
          rewrite /wp-admin$ $scheme://$host$request_uri/ permanent;
          rewrite ^(/[^/]+)?(/wp-.*) $2 last;
          rewrite ^(/[^/]+)?(/.*\.php) $2 last;
        }

        location ~ \.php$ {
          try_files $uri =404;
          fastcgi_pass unix:${config.languages.php.fpm.pools.web.socket};
          include ${pkgs.nginx}/conf/fastcgi.conf;
        }
    '' + (builtins.readFile ./conf/nginx/locations) + "}";
  };

  # Mailpit
  services.mailpit = { enable = false; };

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  enterShell = ''
    php --version
  '';

  processes.open-url.exec = ''
    echo "🚀 PHP is running at: http://${server_name}:${toString listen_port}"

    if command -v xdg-open > /dev/null; then
      xdg-open http://${server_name}:${toString listen_port}
    elif command -v open > /dev/null; then
      open http://${server_name}:${toString listen_port}
    else
      echo "⚠️ Could not auto-open browser."
    fi

    # Prevent the process from exiting immediately so it's visible in logs
    sleep 600
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/pre-commit-hooks/
  # pre-commit.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
