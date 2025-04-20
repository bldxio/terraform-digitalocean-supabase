# Main server block for supabase.* domains (HTTPS)
# Environment: ${environment}
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name supabase.*;

    include /config/nginx/ssl.conf;

    client_max_body_size 20m;

    # STUDIO - Only accessible from Tailscale network
    location / {
        # Restrict access to Tailscale IPs only (100.64.0.0/10 is the Tailscale IP range)
        allow 100.64.0.0/10;
        deny all;

        # We still use basic auth as a second layer of security
        auth_basic "Restricted";
        auth_basic_user_file /config/nginx/.htpasswd;

        # Add environment header for debugging/identification
        add_header X-Environment "${environment}";

        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app studio;
        set $upstream_port 3000;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }

    # REST
    location ~ ^/rest/v1/(.*)$ {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app kong;
        set $upstream_port 8000;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }

    # GRAPHQL
    location ~ ^/graphql/v1/(.*)$ {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app kong;
        set $upstream_port 8000;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }

    # AUTH
    location ~ ^/auth/v1/(.*)$ {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app kong;
        set $upstream_port 8000;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }

    # REALTIME
    location ~ ^/realtime/v1/(.*)$ {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app kong;
        set $upstream_port 8000;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }

    # Storage
    location ~ ^/storage/v1/(.*)$ {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app kong;
        set $upstream_port 8000;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
    # Needed to solve https://github.com/supabase/supabase/issues/11136
    add_header Content-Security-Policy "upgrade-insecure-requests";
}

# HTTP redirects for supabase.* domains
server {
    listen 80;
    listen [::]:80;
    server_name supabase.*;

    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}

# Dedicated server block for Tailscale hostnames - HTTP (redirect to HTTPS)
server {
    listen 80;
    listen [::]:80;

    # Match both supastudio and the full Tailscale domain with environment
    server_name supastudio-${environment} supastudio-${environment}.tailb6eab3.ts.net;

    # Add debug logging for troubleshooting
    error_log /config/log/nginx/supastudio-error.log debug;
    access_log /config/log/nginx/supastudio-access.log;

    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}

# Dedicated server block for Tailscale hostnames - HTTPS
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    # Match both supastudio and the full Tailscale domain with environment
    server_name supastudio-${environment} supastudio-${environment}.tailb6eab3.ts.net;

    # Use the Tailscale certificates from the mounted directory
    ssl_certificate /config/tailscale_certs/supastudio-${environment}.tailb6eab3.ts.net.crt;
    ssl_certificate_key /config/tailscale_certs/supastudio-${environment}.tailb6eab3.ts.net.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    # Reduce SSL verification requirements for Tailscale certificates
    ssl_verify_client off;
    ssl_verify_depth 1;

    # Add debug logging for troubleshooting
    error_log /config/log/nginx/supastudio-https-error.log debug;
    access_log /config/log/nginx/supastudio-https-access.log;

    # Make sure correct client IP is detected
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    # Direct access to studio via Tailscale hostname
    location / {
        # Allow all IPs temporarily for debugging
        # allow 100.64.0.0/10;
        # allow 127.0.0.1;
        # allow 172.18.0.0/16;  # Docker network
        # deny all;

        # Basic auth for additional security
        auth_basic "Restricted";
        auth_basic_user_file /config/nginx/.htpasswd;

        # Debug headers
        add_header X-Debug-Remote-Addr $remote_addr;
        add_header X-Debug-Real-IP $realip_remote_addr;
        add_header X-Environment "${environment}";

        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app studio;
        set $upstream_port 3000;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}
