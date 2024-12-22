#!/bin/bash

# Check if need to install WordPress
if [ ! -f /var/www/html/.post-install-complete ]; then
    rm -f /var/www/html/.post-install-failed
    
    cd /var/www/html
    export XDEBUG_MODE=off

    # Override WP_URL if PUBLIC_URL is set
    if [ -n "$PUBLIC_URL" ]; then
        M2_URL="$PUBLIC_URL"
    fi

    # Install Magento 2 
    su -s /bin/bash www-data -c "bin/magento setup:install \
    --base-url=$M2_URL \
    --db-host=$M2_DB_HOST \
    --db-name=$M2_DB_NAME \
    --db-user=$M2_DB_USER \
    --db-password=$M2_DB_PASSWORD \
    --skip-db-validation \
    --backend-frontname=$M2_BACKEND_FRONTNAME \
    --admin-firstname=$M2_ADMIN_FIRSTNAME \
    --admin-lastname=$M2_ADMIN_LASTNAME \
    --admin-email=$M2_ADMIN_EMAIL \
    --admin-user=$M2_ADMIN_USER \
    --admin-password=$M2_ADMIN_PASSWORD \
    --language=$M2_LANGUAGE \
    --currency=$M2_CURRENCY \
    --timezone=$M2_TIMEZONE \
    --use-rewrites=1 \
    --search-engine=elasticsearch7 \
    --elasticsearch-host=$M2_ELASTICSEARCH_HOST \
    --elasticsearch-port=$M2_ELASTICSEARCH_PORT \
    --elasticsearch-enable-auth=0 \
    --elasticsearch-index-prefix=$M2_ELASTICSEARCH_INDEX_PREFIX \
    --elasticsearch-timeout=$M2_ELASTICSEARCH_TIMEOUT \
    --disable-modules=\
Magento_TwoFactorAuth,\
Magento_AdminAdobeIms,\
Magento_AdminAnalytics,\
Magento_AdobeIms,\
Magento_AdobeImsApi,\
Magento_AdobeStockAdminUi,\
Magento_AdobeStockClient,\
Magento_AdobeStockClientApi,\
Magento_AdobeStockImage,\
Magento_AdobeStockImageApi,\
Magento_AdobeStockImageAdminUi,\
Magento_Analytics,\
Magento_ApplicationPerformanceMonitor,\
Magento_ApplicationPerformanceMonitorNewRelic,\
Magento_Backup,\
Magento_CardinalCommerce,\
Magento_Captcha,\
Magento_Dhl,\
Magento_Fedex,\
Magento_GoogleAdwords,\
Magento_GoogleAnalytics,\
Magento_GoogleGtag,\
Magento_GoogleOptimizer,\
Magento_Paypal,\
Magento_PaypalCaptcha,\
Magento_PaypalGraphQl,\
Magento_PaymentServicesPaypal,\
Magento_PaymentServicesPaypalGraphQl,\
PayPal_Braintree,\
PayPal_BraintreeCustomerBalance,\
PayPal_BraintreeGiftCardAccount,\
PayPal_BraintreeGiftWrapping,\
PayPal_BraintreeGraphQl"
    # || exit 1

    su -s /bin/bash www-data -c "composer config http-basic.repo.magento.com $M2_COMPOSER_REPO_KEY $M2_COMPOSER_REPO_SECRET"
    su -s /bin/bash www-data -c "bin/magento sampledata:deploy && bin/magento setup:upgrade && bin/magento cache:flush"

    touch /var/www/html/.post-install-complete
    
    # chown -R www-data:www-data /var/www/html
fi
echo "✅ Magento 2 installed and configured."