#!/usr/bin/env python3.7

try:
	import sys
	import os
	import configparser
	import mysql.connector
	from mysql.connector import Error

except ImportError as e:
	print("ERROR: Error importing module: " + str(e))
	sys.exit(1)

## GLOBAL DICTS ##
MYSQLSETTINGS = []
GPIOSETTINGS = []
LEDSETTINGS = []

## GLOBAL VARS ##
MySQL_DB_Conn = None
GPIO = None
debug = False

#################

def str2bool(str):
	return str == "T"

def chkArgs(argv):
	global debug
	usageMsg = "usage: " + sys.argv[0] + " <Optional: Debug? (T/F)>"

	if (len(argv) == 1):
		if (argv[0] != 'T' and argv[0] != 'F'):
			print(usageMsg)
			sys.exit(2)
		else:
			debug = str2bool(argv[0])

	# Debug Status
	if (debug):
		print("DEBUG INFO: DEBUGGING ENABLED\n")

def getSettings():
	global MYSQLSETTINGS
	global GPIOSETTINGS
	global GPIO
	global debug
	settings_filename = './settings.ini'

	config = configparser.ConfigParser()
	config.optionxform=str
	config.read(settings_filename)

	# If settings file is missing, print error to CLI and Exit
	if not config.sections():
		print("ERROR: "+ settings_filename + " is missing. Exiting...")
		sys.exit(1)

	# File exists, check sections and options are present. If not, print error to CLI and Exit.
	for section in [ 'MySQL','GPIO' ]:
		if not config.has_section(section):
			print("ERROR: Missing config file section: " + section +". Please check " + settings_filename)
			sys.exit(1)

		if section == 'MySQL':
			for option in [ 'Host','User','Password','Database','Function' ]:
				if not config.has_option(section, option):
					print("ERROR: Missing " + section + " option: " + option +". Please check " + settings_filename)
					sys.exit(1)

		if section == 'GPIO':
			for option in [ 'Enabled','Mode' ]:
				if not config.has_option(section, option):
					print("ERROR: Missing " + section + " option: " + option +". Please check " + settings_filename)
					sys.exit(1)


	# Settings file sections and options valid. Now retrieve/parse values and store in global dicts
	try:
		# Populate MySQL Settings dict
		MYSQLSETTINGS = {
			'HOST':config.get('MySQL', 'Host'),
			'USER':config.get('MySQL','User'),
			'PASSWORD':config.get('MySQL','Password'),
			'DATABASE':config.get('MySQL','Database'),
			'FUNCTION':config.get('MySQL','Function')}
		# Populate GPIO Settings dict
		GPIOSETTINGS = {
			'ENABLED':config.getboolean('GPIO', 'Enabled'),
			'MODE':config.get('GPIO', 'Mode')}

		################## DEBUGGING ##################
		if (debug):
			print("DEBUG INFO: Dumping dictionary Keys & Values:\n")
			for key, value in MYSQLSETTINGS.items():
				print('MySQL:', key, value)
			for key, value in GPIOSETTINGS.items():
				print('GPIO: ', key, value)
			print("\nDEBUG INFO: Dictionary dump complete")
		###############################################

		# If GPIO is enabled, try to import RPi.GPIO module and configure GPIO outputs
		if (GPIOSETTINGS['ENABLED']):
			print("INFO: GPIO is enabled in the settings file.")
			try:
				import RPi.GPIO as GPIO
			except ImportError as e:
				print("ERROR: Error importing RPi.GPIO module: " + str(e))
				sys.exit(1)

			# Check GPIO Mode in settings file to make sure it is valid
			if (GPIOSETTINGS['MODE'] == "GPIO.BCM"):
				print("INFO: Setting GPIO Mode to GPIO.BCM")
				GPIO.setmode(GPIO.BCM)
			elif (GPIOSETTINGS['MODE'] == "GPIO.BOARD"):
				print("INFO: Setting GPIO Mode to GPIO.BOARD")
				GPIO.setmode(GPIO.BOARD)
			else:
				print("ERROR: Invalid value for GPIO.MODE in settings file.")
				sys.exit()

			try:
				GPIO.setwarnings(False)
			except:
				print("ERROR: Error configuring RPi.GPIO module: " + str(sys.exc_info()))
				sys.exit(1)
			print("INFO: Successfully imported & configured RPi.GPIO module.")
		else:
			print("INFO: GPIO is NOT enabled in the settings file.")

	except ValueError as e:
		print("ERROR: Unable to parse values from settings file: \n" + str(e))
		sys.exit(1)

def establish_db_connection():
	global MySQL_DB_Conn
	global debug
	global MYSQLSETTINGS

	if (debug):
		print("DEBUG INFO: Attempting to connect to " + MYSQLSETTINGS['DATABASE'] + '@' + MYSQLSETTINGS['HOST'] +
		" using '" + MYSQLSETTINGS['USER'] + "' as the User and '" + MYSQLSETTINGS['PASSWORD'] + "' as the Password.")

	try:
		MySQL_DB_Conn = mysql.connector.connect(host=MYSQLSETTINGS['HOST'],
							database=MYSQLSETTINGS['DATABASE'],
							user=MYSQLSETTINGS['USER'],
							password=MYSQLSETTINGS['PASSWORD'])
		MySQL_DB_Conn.autocommit = True

		if MySQL_DB_Conn.is_connected():
			print('INFO: Connected to ' + MYSQLSETTINGS['DATABASE'] + '@' + MYSQLSETTINGS['HOST'] +  ' MariaDB database.')

	except Error as e:
		print("ERROR: Error occurred while trying to connect to the MariaDB database: ", str(e))
		sys.exit(1)

def disconnect_db_connection():
	global MySQL_DB_Conn

	try:
		if MySQL_DB_Conn.is_connected():
			MySQL_DB_Conn.close()
			print("INFO: Disconnected from MariaDB database.")
	except Error as e:
		print("ERROR: Error occurred while trying to disconnect from the MariaDB database: ", str(e))
		sys.exit(1)

def control_led(gpio_pin, brightness = 100, frequency = 1, enabled_value = None):
	global debug
	global MySQL_DB_Conn
	global GPIO

	print("INFO: Setting LED on GPIO Pin " + str(gpio_pin) + ". Frequency: " + str(frequency) + ", Brightness: " + str(brightness))
	try:
		# Setup LED
		GPIO.setup(gpio_pin, GPIO.OUT)
		pwm_pin = GPIO.PWM(gpio_pin, frequency)
		pwm_pin.start(brightness)

		# Update database only if value for enabled is passed
		if (enabled_value is not None):
			if (debug):
				print("DEBUG INFO: Attempting to update database.")

			sql = ("UPDATE gpio_def SET enabled = " + str(enabled_value)  + " WHERE pin = " + str(gpio_pin))

			if (debug):
				print("DEBUG INFO: SQL to update database: ")
				print(sql)
			try:
				cursor = MySQL_DB_Conn.cursor()
				cursor.execute(sql)
				print("INFO: Database updated successfully. Set 'enabled' value to (" + str(enabled_value) + ") for GPIO Pin "  + str(gpio_pin) + ".")
			except Error as e:
				print("ERROR: Error occurred while trying to update database: ", str(e))
				sys.exit(1)
		else:
			print("INFO: Database update not required.")
	except:
		print("ERROR: Unexpected error trying to control LED:", sys.exc_info())
		raise

def main():
	global GPIOSETTINGS
	global MySQL_DB_Conn
	global debug
	STATUS_GPIO_REC = None
	LED_ENABLED_PIN = None

	# Get Current Status
	if (debug):
		print("DEBUG INFO: Now attempting to retrieve current status from database.")

	query = ("SELECT " + MYSQLSETTINGS['FUNCTION'] + ";")

	if (debug):
		print("DEBUG INFO: Query to obtain current status: ")
		print(query)

	try:
		cursor = MySQL_DB_Conn.cursor(named_tuple=False)
		cursor.execute(query)
		result = cursor.fetchone()
		status = str(result[0])

		if (debug):
			print("DEBUG INFO: Result returned from query: " + str(status))

		if len(status) > 0:
			if str(status) == 'F':
				################ TODO: SWITCH ON FLASHING RED LED? ####################################
				print("ERROR: Function to retrieve current status returned Fault value! Check database.")
				sys.exit(1)
			else:
				print("INFO: Retrieved current status from database.")
		else:
			print("ERROR: Function to retrieve current status returned no value! Check database.")
			sys.exit(1)
	except Error as e:
		print("ERROR: Error occurred while trying to retrieve current status from database: ", str(e))
		sys.exit(1)

	# Lookup GPIO definition
	if (debug):
		print("DEBUG INFO: Now attempting to lookup GPIO definition from database.")

	query = ("""SELECT * FROM gpio_def gd WHERE gd.status = '""" + str(status) + """' LIMIT 1""")

	if (debug):
		print("DEBUG INFO: Query to lookup GPIO definition based on current status: ")
		print(query)

	try:
		cursor = MySQL_DB_Conn.cursor(dictionary=True)
		cursor.execute(query)
		result = cursor.fetchone()

		if result == None:
			################ TODO: SWITCH ON FLASHING RED LED? #####
			print("ERROR: GPIO definition NOT found! Check database.")
			sys.exit(1)
		else:
			STATUS_GPIO_REC = result
			################## DEBUGGING ##################
			if (debug):
				print("DEBUG INFO: Dumping GPIO definition dictionary Keys & Values:\n")
				for key, value in STATUS_GPIO_REC.items():
					print(key, value)
				print("\nDEBUG INFO: GPIO definition dictionary dump complete")
			###############################################
			print("INFO: GPIO definition found based on current status.")
	except Error as e:
		print("ERROR: Error occurred while trying to lookup GPIO definition based on current status: ", str(e))
		sys.exit(1)

	# Determine if an LED is currently illuminated
	if (debug):
		print("DEBUG INFO: Now attempting to determine whether an LED is currently illuminated.")

	query = ("""SELECT gd.pin FROM gpio_def gd WHERE gd.enabled = 'Y' LIMIT 1""")

	if (debug):
		print("DEBUG INFO: Query to lookup if LED is currently illuminated: ")
		print(query)

	try:
		cursor = MySQL_DB_Conn.cursor(dictionary=True)
		cursor.execute(query)
		result = cursor.fetchone()
	except Error as e:
		print("ERROR: Error occurred while querying database for enabled LED: ", str(e))
		sys.exit(1)

	if result == None:
		print("INFO: No LEDs are currently illuminated.")
	else:
		LED_ENABLED_PIN = result['pin']
		print("INFO: LED on GPIO Pin " + str(LED_ENABLED_PIN) + " is currently illuminated.")

		# Determine whether same LED should stay illuminated or whether a different LED needs to be illuminated.
		if STATUS_GPIO_REC['pin'] != LED_ENABLED_PIN:
			print("INFO: LED determined by current status is different to currently illuminated LED. Change needed!")
			# Turn off LED which is currently illuminated.
			if (GPIOSETTINGS['ENABLED']):
				control_led(LED_ENABLED_PIN,0,1,'NULL')
			else:
				print("INFO: Turning off GPIO Pin " + str(LED_ENABLED_PIN) + " will not occur as GPIO is not enabled.")
		else:
			print("INFO: LED determined by current status is currently illuminated. No change needed!")
			return

	#  Turn on relevant LED as determined by current status.
	if (GPIOSETTINGS['ENABLED']):
		control_led(STATUS_GPIO_REC['pin'], STATUS_GPIO_REC['brightness'], STATUS_GPIO_REC['flash_freq'],"'Y'")
	else:
		print("INFO: Turning on GPIO Pin " + str(STATUS_GPIO_REC['pin']) + " will not occur as GPIO is not enabled.")

if __name__ == '__main__':

	# First check that script is being run as root user.
	if not os.geteuid() == 0:
		print("ERROR: This Python script must be run as root.")
		sys.exit(1)
	# Script is being run as root. Continue...
	chkArgs(sys.argv[1:])
	getSettings()
	establish_db_connection()
	main()
	disconnect_db_connection()
	# Program complete. Exit cleanly
	print("INFO: Process completed successfully. Exiting...")
	sys.exit(0)
