# Juan Sebastian Casallas, Ashwin Natarajan, Keji Hu
# 2012 Iowa State University
# CS 573: Machine Learning
# Project

from subprocess import check_output	# Make system calls (returning their output)
from subprocess import STDOUT
from os import remove			# Used for deleting temporary files
from os import listdir			# List all the files in a directory
from os import makedirs			# Make intermediate directories
from shutil import move			# Move files

# Converts a csv file to arff, if arff_file exists, it is overwritten
def csv_to_arff(csv_file,arff_file):
	converter = 'weka.core.converters.CSVLoader'
	# We need to use 'shell=True' to be able to output to the arff file via console
	cmd = 'java '+converter+' '+csv_file+' > '+arff_file
	# Calling cmd might print some errors concerning the
	print cmd
	res = check_output(cmd,stderr=STDOUT,shell=True)

# The CSV filter leaves all the attributes as numeric, so we need to correct that
def numeric_to_nominal(input, output, cols_to_change='first-last',class_pos='last'):
	filter = 'weka.filters.unsupervised.attribute.NumericToNominal'
	# -R: columns to convert
	# -c: class position
	cmd = ['java', filter, '-R', cols_to_change ,'-c', class_pos, '-i', input, '-o', output]
	print ' '.join(cmd)
	check_output(cmd)

# The CSV filter leaves all the attributes as numeric, so we need to correct that
def remove_attributes(input, output, cols_to_delete,class_pos='last'):
	filter = 'weka.filters.unsupervised.attribute.Remove'
	# -R: columns to convert
	# -c: class position
	cmd = ['java', filter, '-R', cols_to_delete ,'-c', class_pos, '-i', input, '-o', output]
	print ' '.join(cmd)
	check_output(cmd)

# Converts the collision data file to an arff file with the same name but different extension
# If there was already an arff file with this name, it will be overwritten
def collision_file_to_arff(data_file_name):
	# Create a temporary csv file
	tmp_name = data_file_name.rpartition('.')[0]
	
	print 'Converting '+data_file_name+' to '+tmp_name+'.arff'
	# Now we can convert the temporary csv to arff
	csv_to_arff(data_file_name,tmp_name+'.arff')
	
	print 'Removing unnecessary attributes'
	# These attributes don't change throughout the trials
	useless_cols = ['44'] # Number of balls
	useless_cols.append('47-48') # Ball 1 y,z
	
	if data_file_name.find('2sph') >= 0:
		useless_cols.append('51-52') # Ball 2 y,z
	elif data_file_name.find('3sph') >= 0:
		useless_cols.append('51-52') # Ball 2 y,z
		useless_cols.append('55-56') # Ball 3 y,z
	
	# Convert it to a comma-separated list of strings
	useless_cols = ','.join(useless_cols)
	
	remove_attributes(tmp_name+'.arff',tmp_name+'2.arff',useless_cols)
	
	print 'Converting numeric to nominal'
	# These attributes are initially numeric, but they are better off nominal
	numeric_cols = []
	if data_file_name.find('1sph') >= 0:
		numeric_cols.append('44-46') # ball 1 size, ball 1 x, collision 1
	elif data_file_name.find('2sph') >= 0:
		numeric_cols.append('44-49') # same as above + ball2 size, ball2 x, collision 2
	elif data_file_name.find('3sph') >= 0:
		numeric_cols.append('44-52') # same as above + ball3 size, ball3 x, collision 3
	
	# Convert it to a comma-separated list of strings
	numeric_cols = ','.join(numeric_cols)
	
	numeric_to_nominal(tmp_name+'2.arff',tmp_name+'.arff', numeric_cols)
	
	print 'Removing temporary '+tmp_name+'2.arff'	
	# Remove the temporary arff file
	remove(tmp_name+'2.arff')
	
	return tmp_name+'.arff'

prefix = '../data/'

path=prefix+'parsed/'  # path to the parsed data

outdir = prefix+'weka/' # path to the output arffs
try:
	makedirs(outdir) # Create output directory
except:
	print "Output directory "+outdir+" already exists"

import sys

dirs=listdir(path) # Each user has its own directory
for dir in dirs:
	try:
		print "== Parsing directory "+path+dir " =="
		#outdir = prefix+'weka/'+dir
		#print "Make output directory "+outdir
		#try:
		#	makedirs(outdir) # Create output directory
		#except:
		#	print "Directory already existent"
		files = listdir(path+dir) # Now get all the files in the user's directory
		print files
		for file in files:
			if file.find(".txt") < 0 and file.find(".csv") < 0: 
				continue # Skip non-csv files
			
			outfile = collision_file_to_arff(path+dir+"/"+file) # Generate the arff

			print outfile			
			# Now move the arff file to a different location
			src_name = outfile
			
			dest_name = outfile.rpartition('/')[2] # Get rid of the path of the filename
			dest_name = dest_name.rpartition('_log')[0] # Get rid of the "_log" part of the filename
			dest_name = dir+"_"+dest_name+".arff" # Prepend "numParticipant_"
			dest_name = outdir + dest_name # Prepend output dir
			
			print "Move "+ src_name +" to "+ dest_name
			try:
				move(src_name,dest_name)
			except:
				print sys.exc_info()[0]
	except: 
		pass # This is a file and not a directory, skip
