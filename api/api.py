#!/usr/bin/env python3.7

try:
	import sys
	import os
	from flask import Flask, redirect, url_for, request, jsonify, make_response
	import configparser
	import mysql.connector
	from mysql.connector import Error
	import atexit

except ImportError as e:
	print("ERROR: Error importing module: " + str(e))
	sys.exit(1)

##### GLOBAL VARIABLES #####
DEBUG = False
SETTINGS = []
FLASKAPP = Flask(__name__)

############################

def exit_app():
	print("INFO: Exiting...")

def createJSONResponse(istatus="null", imessage="null", ihttpstatuscode=200):
	oresponse = make_response(jsonify(
					{	"status": str(istatus),
						"message": str(imessage)
					}),	ihttpstatuscode,)

	oresponse.headers["Content-Type"] = "application/json"
	return oresponse

def load_settings():
	global DEBUG
	global SETTINGS
	settings_filename = 'settings.ini'

	if DEBUG:
		print("DEBUG: Settings file: " + settings_filename)

	config = configparser.ConfigParser()
	config.read(settings_filename)

	# If settings file is missing, print error to CLI and Exit
	if not config.sections():
		print("ERROR: "+ settings_filename + " is missing. Exiting...")
		sys.exit(1)
	# File exists, check sections and options are present. If not, print error to CLI and Exit.
	for section in [ 'MySQL' ]:

		if not config.has_section(section):
			print("ERROR: Missing settings section: " + section +". Please check " + settings_filename + ". Exiting...")
			sys.exit(1)

		if section == 'MySQL':
			for option in [ 'Host', 'User', 'Password', 'Database' ]:
				if not config.has_option(section, option):
					print("ERROR: Missing MySQL settings option: " + option +". Please check " + settings_filename + ". Exiting...")
					sys.exit(1)

	# Settings file sections and options valid. Now retrieve/parse values and store in global dicts
	try:

		SETTINGS = {	'MYSQL_HOSTNAME':config.get('MySQL', 'Host'),
				'MYSQL_DATABASE':config.get('MySQL', 'Database'),
				'MYSQL_USER':config.get('MySQL', 'User'),
				'MYSQL_PASSWORD':config.get('MySQL', 'Password')}

		if DEBUG:
			print("DEBUG: Settings file contains following keys & values:")
			for key, value in SETTINGS.items():
				print(key + ": ", value)

	except ValueError as e:
		print("ERROR: Unable to parse values from settings file: \n" + str(e))
		sys.exit(1)

def new_db_connection():
	try:
		global DEBUG
		global SETTINGS

		if DEBUG:
			print("DEBUG: Attempting to connect to " + SETTINGS['MYSQL_DATABASE'] + '@' + SETTINGS['MYSQL_HOSTNAME'] +
			" using '" + SETTINGS['MYSQL_USER'] + "' as the User and '" + SETTINGS['MYSQL_PASSWORD'] + "' as the Password.")

		MySQL_DB_Conn = mysql.connector.connect(host=SETTINGS['MYSQL_HOSTNAME'],
							database=SETTINGS['MYSQL_DATABASE'],
							user=SETTINGS['MYSQL_USER'],
							password=SETTINGS['MYSQL_PASSWORD'])
		MySQL_DB_Conn.autocommit = True

		if MySQL_DB_Conn.is_connected():
			print('INFO: Connected to ' + SETTINGS['MYSQL_DATABASE'] + '@' + SETTINGS['MYSQL_HOSTNAME'] +  ' MariaDB database.')
			return MySQL_DB_Conn
		else:
			return None

	except Error as e:
		print("ERROR: Error occurred while trying to connect to the MariaDB database: ", str(e))
		return None

def isParamsValid(idbconn, icheckcode, istatuscode, icontextcode):
	cursor = idbconn.cursor(named_tuple=False)

	query = ("""SELECT EXISTS(SELECT 1
		FROM check_def cd
		JOIN status_def sd ON (sd.code = '""" + str(istatuscode) + """' AND sd.active = 'Y')
		JOIN context_def cd2 ON (cd2.code = '""" + str(icontextcode) + """' AND sd.active = 'Y')
		WHERE cd.code = '""" + str(icheckcode) +
		"""' AND cd.active = 'Y');""")

	if DEBUG:
		print("DEBUG: Query to check whether parameters are valid: ")
		print(query)
	try:
		#Execute query
		cursor.execute(query)
		#Fetch single row from executed query
		result = cursor.fetchone()

		if DEBUG:
			print("DEBUG: Result returned from query: " + str(result[0]))
		if str(result[0]) == '1':
			print("INFO: Parameters are valid.")
			return True
		else:
			print("INFO: Parameters are not valid, check database.")
			return False
	except Error as e:
		print("ERROR: Unexpected error checking whether parameters are valid: ", str(e))
	finally:
		del cursor

def init_app():

	os.environ["FLASK_ENV"] = "development"
	atexit.register(exit_app)
	FLASKAPP.run(host='0.0.0.0', debug=DEBUG, use_reloader=False, threaded=True)

@FLASKAPP.route('/', methods=['GET'])
def home():
	global SETTINGS
	MySQL_DB_Conn = new_db_connection()
	db_status_str = None

	if MySQL_DB_Conn is not None:
		if MySQL_DB_Conn.is_connected():
			#Connected to Database
			db_status_str = '<b><p style="color:green">Connection test successful to ' + SETTINGS['MYSQL_DATABASE'] + '@' + SETTINGS['MYSQL_HOSTNAME'] +  ' MariaDB database.</p></b>'
		else:
			#Not connected to Database
			db_status_str = '<b><p style="color:red">Connection test unsuccessful to ' + SETTINGS['MYSQL_DATABASE'] + '@' + SETTINGS['MYSQL_HOSTNAME'] +  ' MariaDB database.</p></b>'
	else:
		db_status_str = '<b><p style="color:red">Unable to connect to the Raspberry Pi Health Check MariaDB database. Check Settings!</p></b>'

	header = "<h1>Raspberry Pi Health Check API</h1>"
	bodyline1 = "<p>This API provides a method for inserting data into the Raspberry Pi Health Check MariaDB SQL Database.</p>"
	bodyline2 = db_status_str

	html_str = header + bodyline1 + bodyline2

	del MySQL_DB_Conn
	return html_str

@FLASKAPP.route('/dbconnectioncheck', methods=['GET'])
def dbConnectionCheck():
	global SETTINGS
	global DEBUG
	db_status_str = None

	if DEBUG:
		print("DEBUG: DB Connection Check called.")

	MySQL_DB_Conn = new_db_connection()

	if MySQL_DB_Conn is not None:
		try:
			if MySQL_DB_Conn.is_connected():
				db_status_str = "Connection test successful to " + SETTINGS['MYSQL_DATABASE'] + '@' + SETTINGS['MYSQL_HOSTNAME'] +  " MariaDB database."
				return createJSONResponse('0', str(db_status_str),200)
			else:
				db_status_str = "Connection test unsuccessful to " + SETTINGS['MYSQL_DATABASE'] + '@' + SETTINGS['MYSQL_HOSTNAME'] +  " MariaDB database."
				return createJSONResponse('-1', str(db_status_str),500)
		except Error as e:
			return createJSONResponse('-1',"API Health Check failed: " + str(e),500)
		finally:
			del MySQL_DB_Conn
	else:
		del MySQL_DB_Conn
		return createJSONResponse('-1',"Unexpected error occurred when trying to connect to MariaDB database.",500)

@FLASKAPP.route('/insert/checklog', methods=['GET', 'POST'])
def insertCheckLog():
	global SETTINGS
	global DEBUG

	if request.method == "GET":
		parameters = request.args

		for parameter in [ 'code', 'status', 'context', 'comment', 'hostname' ]:
			if parameter not in parameters:
				return createJSONResponse('-1',"Missing \'" + str(parameter) + "\' parameter in call.",406)

		MySQL_DB_Conn = new_db_connection()

		if MySQL_DB_Conn is not None:

			if MySQL_DB_Conn.is_connected():
				if DEBUG:
					print("DEBUG: Incoming INSERT CHECKLOG API Request parameters:")
					for key, value in parameters.items():
						print(key + ": ", value)

				if isParamsValid(MySQL_DB_Conn, parameters['code'], parameters['status'], parameters['context']):

					add_check_log = ("INSERT INTO check_log "
							"(check_code, status_code, context_code, comment, hostname) "
							"VALUES (%s, %s, %s, %s, %s)")

					data_check_log = (str(parameters['code']), str(parameters['status']), str(parameters['context']), str(parameters['comment']), str(parameters['hostname']))

					cursor = MySQL_DB_Conn.cursor()

					try:
						cursor.execute(add_check_log, data_check_log)

						return createJSONResponse('0',"Successfully inserted record into Check Log table. Row ID: " + str(cursor.lastrowid),200)
					except Error as e:
						return createJSONResponse('-1',"Failed to insert record into Check Log table: " + str(e),500)
					finally:
						del cursor
						del MySQL_DB_Conn
				else:
					del MySQL_DB_Conn
					return createJSONResponse('-1',"Failed to insert record into Check Log table, input parameters are not valid.",500)
			else:
				del MySQL_DB_Conn
				return createJSONResponse('-1',"Failed to insert record into Check Log table, not connected to MariaDB database.",500)
		else:
			del MySQL_DB_Conn
			createJSONResponse('-1',"Unexpected error occurred when trying to connect to MariaDB database.",500)

if __name__ == "__main__":

	if (DEBUG):
		print("INFO: DEBUG mode enabled!")
	load_settings()
	init_app()
	sys.exit(0)
