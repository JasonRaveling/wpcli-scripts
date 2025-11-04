#!/bin/env bash

# Adds your reCAPTCHA keys in Gravity Forms for every site.

source 'source/includes.sh';

site_key='';
secret_key='';
type='checkbox'; # Can be `checkbox` or `invisible`.

for s in $(wp_skip_all site list --field='url'); do
        echo "Current site being updated: $s"
        wp_skip_all option update rg_gforms_captcha_public_key "$site_key" --url="${s}";
        wp_skip_all option update rg_gforms_captcha_private_key "$secret_key" --url="${s}";
        wp_skip_all option update rg_gforms_captcha_type $type --url="${s}";
        wp_skip_all option update gform_recaptcha_keys_status 1 --url="${s}";
done;
