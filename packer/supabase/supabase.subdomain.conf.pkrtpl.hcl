# --- PUBLIC API ENDPOINTS (supabase.bldx.one) ---
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name supabase.bldx.one;

    include /config/nginx/ssl.conf;
    client_max_body_size 20m;

    # API Endpoints (no auth)
    location ~ ^/(rest|auth|graphql|realtime|storage|functions)/v1/(.*)$ {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app kong;
        set $upstream_port 8000;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }

    # Optionally, block or return a message for / (no Studio here)
    location / {
        return 404 "Not Found. This endpoint is for API access only.";
    }

    add_header Content-Security-Policy "upgrade-insecure-requests";
}

# --- STUDIO & API ON TAILSCALE/LAN (supabase, supabase.tail*.ts.net) ---
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name supabase supabase.*;

    include /config/nginx/ssl.conf;
    client_max_body_size 20m;

    # Studio dashboard (protected by basic auth)
    location / {
        auth_basic "Restricted";
        auth_basic_user_file /config/nginx/.htpasswd;
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app studio;
        set $upstream_port 3000;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }

    # API Endpoints (optional: allow API access from Tailscale/LAN)
    location ~ ^/(rest|auth|graphql|realtime|storage|functions)/v1/(.*)$ {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app kong;
        set $upstream_port 8000;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }

    add_header Content-Security-Policy "upgrade-insecure-requests";
}
