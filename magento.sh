#!/bin/bash
# Not modify line below
# Init environment
# chmod +x /path_to_your_file/magento.sh
# ln -s /path_to_your_file/magento.sh /usr/bin/magento
# open terminal type magento 

OWNER=`whoami`;
GROUP=`whoami`;

MAGE_PUBLIC_KEY=your_magento_public_key
MAGE_PRIVATE_KEY=your_magento_private_key


SCRIPTNAME=`basename "$0"`
echo "============================================================="
echo "Welcome $SCRIPTNAME Panel!"
echo "============================================================="

function isMagento()
{
	cd `pwd`
	if [ -f bin/magento ]
	then
		return 1
	else   
		echo -e "${White} ${On_Red}"
			echo "#######################################################"
			echo "You need go to root magento before run this commmand."
			echo "Your current locatlion: $(pwd)"
			echo "#######################################################"
		echo -e "${NC}"
		$SCRIPTNAME
	fi	
}

function commandMagento()
{
	if [ "$1" != "" ] ; then
		local command=$1;
	else 
		echo -n 'Enter command: '
		read command		
	fi
	isMagento
	if [ $? == 1 ] ; then
		eval "$command"
	fi
}



function upgradeMagento2x()
{
	cpath=`pwd`
	isMagento
	if [ $? == 1 ] ; then
		chmod u+x bin/magento
	fi
# sudo -i -u ${OWNER} bash << EOF
	cd ${cpath}
	pwd
	cp composer.json composer.json.bak
	echo "Current version: "
	bin/magento --version
	echo "All version magento availabel: "
	composer config -a http-basic.repo.magento.com ${MAGE_PUBLIC_KEY} ${MAGE_PRIVATE_KEY}
	composer show magento/product-community-edition 2.* --all | grep -m 1 versions
# EOF
	echo "########################################"
	echo -n "Enter version you want to Upgrade! : "
	read  version

# sudo -i -u ${OWNER} bash << EOF
	cd ${cpath}
	pwd
	bin/magento config:set system/backup/functionality_enabled 1
	bin/magento setup:backup --db
	bin/magento maintenance:enable
	bin/magento deploy:mode:set default

	composer require magento/product-community-edition ${version} --no-update
	composer update
	bin/magento setup:upgrade
	bin/magento indexer:reindex
	bin/magento setup:static-content:deploy -f
	# Remove all files in var exception directory backups
	#find ./var ! -name 'backups' -type f -exec rm -f {} +
	# Remove file auth account
	# rm -rf auth.json

	bin/magento deploy:mode:set production
	bin/magento maintenance:disable
	find . -type d -exec chmod 755 {} \; && find . -type f -exec chmod 644 {} \;
# EOF

	echo "Upgrade Done!."
}

function defaultMode ()
{
	php bin/magento maintenance:enable

	php -dmemory_limit=-1 bin/magento deploy:mode:set default
	php bin/magento setup:upgrade
	php bin/magento config:set dev/css/minify_files 0
	php bin/magento config:set dev/css/merge_css_files 0
	php bin/magento config:set dev/js/minify_files 0
	php bin/magento config:set dev/js/merge_files 0
	php bin/magento config:set dev/js/enable_js_bundling 0
	php bin/magento config:set dev/static/sign 1
	php bin/magento config:set dev/debug/template_hints_storefront 1
	php bin/magento config:set dev/debug/template_hints_storefront_show_with_parameter 1
	php bin/magento config:set dev/debug/template_hints_blocks 1
	php bin/magento config:set dev/template/allow_symlink 1
	rm -rf pub/static/frontend/* && rm -rf var/view_preprocessed
	php bin/magento setup:static-content:deploy -f
	php bin/magento cache:flush
	php bin/magento cache:enable

	php bin/magento maintenance:disable
	echo 'Enable Default Mode done!';
}
function productionMode ()
{
	php bin/magento maintenance:enable
	
	php bin/magento setup:upgrade
	php -dmemory_limit=-1 bin/magento deploy:mode:set production --skip-compilation
	php bin/magento config:set dev/css/minify_files 1
	php bin/magento config:set dev/css/merge_css_files 1
	php bin/magento config:set dev/js/minify_files 1
	php bin/magento config:set dev/js/merge_files 0
	php bin/magento config:set dev/js/enable_js_bundling 1
	php bin/magento config:set dev/static/sign 1
	php bin/magento config:set dev/debug/template_hints_storefront 0
	php bin/magento config:set dev/debug/template_hints_storefront_show_with_parameter 0
	php bin/magento config:set dev/debug/template_hints_blocks 0
	php bin/magento config:set dev/template/allow_symlink 0
	rm -rf pub/static/frontend/* && rm -rf var/view_preprocessed
	php bin/magento setup:static-content:deploy -f
	php bin/magento cache:flush
	php bin/magento cache:enable
	
	php bin/magento maintenance:disable
	echo 'Enable Production Mode done!';
}

function main ()
{
	prompt="Enter number option:"
	options=( 
		"Exit"
		"php bin/magento cache:flush block_html" 
		"php bin/magento cache:flush layout" 
		"php bin/magento cache:flush" 
		"php bin/magento setup:upgrade" 
		"php bin/magento indexer:reindex"
		"php bin/magento setup:di:compile"
		"rm -rf pub/static/frontend/* && rm -rf var/view_preprocessed && php bin/magento setup:static-content:deploy -f"
		"################################"
		"php bin/magento config:set dev/static/sign 1"
		"php bin/magento config:set web/secure/use_in_adminhtml 1"
		"php bin/magento setup:backup --db"
		"Enable Template Path Hints with Parameter Value magento"

		"Enabled default Mode"
		"Enabled Production Mode"

		"rm -rf generated"
		"Upgrade M2 version"
		"find `pwd` -type d -exec chmod 755 {} \;  find . -type f -exec chmod 644 {} \; find . -name ".DS_Store" -delete;"
		"sudo service elasticsearch restart"
		"Test elasticsearch curl localhost:9200"
	)

	PS3="$prompt"
	select opt in "${options[@]}" ; do 

	    case "$REPLY" in
	    1) clear && echo "Bye !" && killall -g $SCRIPTNAME && clear;;

		2) 	
			commandMagento "php bin/magento cache:flush block_html"
			$SCRIPTNAME
		;;
		
		3) 
			commandMagento "php bin/magento cache:flush layout"
			$SCRIPTNAME
		;;

	    4)
			commandMagento "php bin/magento cache:flush"
			$SCRIPTNAME
		;;

		5)
			commandMagento "php bin/magento setup:upgrade"
			$SCRIPTNAME
		;;

		6)
			commandMagento "php bin/magento indexer:reindex"
			$SCRIPTNAME
		;;

		7)
			commandMagento "php bin/magento setup:di:compile"
			$SCRIPTNAME
		;;

		8)
			commandMagento "rm -rf pub/static/frontend/* && rm -rf var/view_preprocessed"
			commandMagento "php bin/magento setup:static-content:deploy -f"
			$SCRIPTNAME
		;;

		9)
			echo '########################################'
			$SCRIPTNAME
		;;

		10)
			commandMagento "php bin/magento config:set dev/static/sign 1"
			$SCRIPTNAME
		;;		
		11)
			commandMagento "php bin/magento config:set web/secure/use_in_adminhtml 1"
			$SCRIPTNAME
		;;

		12)
			commandMagento "php bin/magento config:set system/backup/functionality_enabled 1 && php bin/magento setup:backup --db"
			$SCRIPTNAME
		;;

		13)
			commandMagento "php bin/magento config:set dev/debug/template_hints_storefront 1"
			commandMagento "php bin/magento config:set dev/debug/template_hints_storefront_show_with_parameter 1"
			commandMagento "php bin/magento config:set dev/debug/template_hints_blocks 1"
			commandMagento "php bin/magento cache:flush config"
		;;

		14)
			defaultMode
			$SCRIPTNAME
		;;

		15)
			productionMode
			$SCRIPTNAME
		;;

		16)
			commandMagento "rm -rf generated"
			echo 'done!';
			$SCRIPTNAME
		;;

		17)
			upgradeMagento2x
			echo 'done!';
			$SCRIPTNAME
		;;

		18)
			find `pwd` -type d -exec chmod 755 {} \;
			find `pwd` -type f -exec chmod 644 {} \;
			echo 'done!';
			$SCRIPTNAME
		;;

		19)
			sudo service elasticsearch restart
		;;

		20)
			curl localhost:9200
		;;

	    *) echo "Input wrong, please input number order on menu !";continue;;

	    esac
	done
}

main