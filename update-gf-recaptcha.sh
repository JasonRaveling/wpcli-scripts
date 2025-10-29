#!/bin/sh

# Adds your reCAPTCHA keys in Gravity Forms for every site on the WP multisite/network.

site_key='';
secret_key='';
type='checkbox'; # Options: checkbox or invisible

for s in $(wp site list --allow-root --field='url'); do
        echo "Current site being updated: $s"
        wp --allow-root option update rg_gforms_captcha_public_key $site_key --url="${s}";
        wp --allow-root option update rg_gforms_captcha_private_key $secret_key --url="${s}";
        wp --allow-root option update rg_gforms_captcha_type $type --url="${s}";
        wp --allow-root option update gform_recaptcha_keys_status 1 --url="${s}";
done;
