#!/bin/bash
#@author @Todi Adiyatmo Wijoyo based on
#@fork from @Julius Zaromskis(http://nicaw.wordpress.com/2013/04/18/bash-backup-rotation-script/)
#@description Backup script for your website

# --------------------------
# Edit this configuration !!
# THESE WILL BE THE SETTINGS
# IF YOU DO NOT SPECIFY THEM
# WITH SWITCHES.
# --------------------------

# --------------------
# Backup Destination option, please read the README to find the possible value
# --------------------

# A Temporary Location to work with files , DO NOT END THE DIRECTORY WITH BACKSLASH !
TMP_DIR=./tmp

# The directory to be backed up , DO NOT END THE DIRECTORY WITH BACKSLASH !
SOURCE_DIR=/dir-that-you-want-to-backup

# The directory where the backups are sent , DO NOT END THE DIRECTORY WITH BACKSLASH !
TARGET_DIR=/dir-where-backups-are-put

# Hostname
HOST="put-your-hostname-here"

# Compression type
COMPRESSION=lzma

# Admin email
MAIL="email-address"

# Email Tag
EMAIL_SUBJECT_TAG="[backup of $SOURCE_DIR@$HOST]"

# Number of day the daily backup keep ( 2 day = 2 daily backup retention)
RETENTION_DAY=5

# Number of day the weekly backup keep (14 day = 2 weekly backup retention )
RETENTION_WEEK=14

# Number of day the monthly backup keep (30 day = 2 montly backup retention)
RETENTION_MONTH=60

# Monthly date backup option (day of month)
MONTHLY_BACKUP_DATE=1

# Weekly day to backup option (day of week - 1 is monday )
WEEKLY_BACKUP_DAY=6

# -----------------
# FTP Configuration
# Enter all data within the ' ' single quote !
# -----------------

#This is the FTP servers host or IP address.
FTP_HOST='ftp.yourhost.com'

#FTP PORT
FTP_PORT=21

#This is the FTP user that has access to the server.
FTP_USER='user'

#This is the password for the FTP user.
FTP_PASSWORD='password'

#The backup directory on remote machine, DO NOT END THE DIRECTORY WITH BACKSLASH !
FTP_TARGET_DIR='ftp_target_dir'

# --------------------------------------------------
# MYSQL Configuration
# Enter all data within the ' ' single quote !
# --------------------------------------------------

DB_USER='put-username-here'
DB_PASSWORD='put-password-here'
DB_DATABASE='put-database-name-here'
DB_HOST='127.0.0.1'

# -------------------------------------------------
# Extra mysqldump option
# -------------------------------------------------
EXTRA_MYSQLDUMP_OPTIONS=''

# --------------------------------------------------
# Default Backup Options
# Here you can set what you want to be backed up by
# Default. 0 = no ; 1 = yes
# If you use the switches and not this config file
# Thes settings will be toggled automatically.
# --------------------------------------------------

# 0 or 1
LOCAL_BACKUP_OPTION=0
FTP_BACKUP_OPTION=0

#--------------------------------------
# You may set when you want to schedule
# a backup of the SQL databases or the
# physical files by setting the number
# between 1-7. The chart below will
# help you know which to pick.
#----------------------------------#
# Daily | Weekly | Monthly | Value #
#-------|--------|---------|-------#
#  Yes  |   No   |    No   |   1   #
#  No   |   Yes  |    No   |   2   #
#  Yes  |   Yes  |    No   |   3   #
#  No   |   No   |   Yes   |   4   #
#  Yes  |   No   |   Yes   |   5   #
#  No   |   Yes  |   Yes   |   6   #
#  Yes  |   Yes  |   Yes   |   7   #
#----------------------------------#

#Between 1-7
SQL_BACKUP_OPTION=0
FILES_BACKUP_OPTION=7

# -----------------
# End configuration
# -----------------

RUN_NOW=0
#------------------
#Begin Switches
#------------------

while [ "$#" -gt 0 ];
do
  case "$1" in
    -h|--help)
      echo "-h|--help was triggered"
      exit 1
      ;;

    --both)
      LOCAL_BACKUP_OPTION=1
      FTP_BACKUP_OPTION=1
      ;;

    --hostname)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
       HOST=$2
       TMP_DIR="$TMP_DIR/$HOST"
       shift
      else
        echo "Error in --hostname syntax. Script failed."
        exit 1
      fi
      ;;

    --compression)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
        if [ "$2" == "lzma" ] || [ "$2" == "gzip" ] || [ "$2" == "none" ]; then
            COMPRESSION=$2
            shift
        else
            echo "Error in --compression syntax. Script failed."
            exit 1
        fi
      fi
      ;;

    --ftp)
      FTP_BACKUP_OPTION=1
      if [ "$#" -gt 1 ]; then
        if [ ! "$2" = \-* ]; then
          if [[ ! "$3" = \-* && ! "$4" = \-* && ! "$5" = \-* && ! "$6" = \-* && ! "$3" == "" && ! "$4" == "" && ! "$5" = "" && ! "$6" = "" ]]; then
            FTP_HOST=$2
            FTP_PORT=$3
            FTP_USER=$4
            FTP_PASSWORD=$5
            FTP_TARGET_DIR=$6
            shift 5
          else
            echo "Error in --ftp syntax. Script failed."
            exit 1
          fi
        fi
      fi
      ;;

    --sql)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
        SQL_BACKUP_OPTION=$2
        if [[ ! "$3" = \-* && ! "$4" = \-* && ! "$5" = \-* && ! "$6" = \-* && ! "$3" == "" && ! "$4" == "" && ! "$5" = "" && ! "$6" = "" ]]; then
            DB_HOST=$3
            DB_USER=$4
            DB_PASSWORD=$5
            DB_DATABASE=$6
            shift 4
        else
            echo "Error in --sql syntax. Script failed."
            exit 1
        fi
        shift
      fi
      ;;

    --now)
      RUN_NOW=1
      ;;

    -bd|--backupdir)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
        FILES_BACKUP_OPTION=$2
        if [[ ! "$3" = \-* && ! "$3" == "" ]]; then
          SOURCE_DIR=${3%/}
          shift 2
        else
          echo "Error in -bd|--backupdir syntax. Script failed."
          exit 1
        fi
      fi
      ;;


    -td|--targetdir)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
       TARGET_DIR=${2%/}
       LOCAL_BACKUP_OPTION=1
       shift
      else
        echo "Error in -td|--targetdir syntax. Script failed."
        exit 1
      fi
      ;;

    -e|--email)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
      MAIL=$2
      shift
      else
        echo "Error in -e|--email syntax. Script failed."
        exit 1
      fi
      ;;

    -r|--retention)
      if [[ "$#" -gt 1 && ! "$2" = \-* && ! "$3" = \-* && ! "$4" = \-* && ! "$3" == "" && ! "$4" == "" ]]; then
        RETENTION_DAY=$2
        RETENTION_WEEK=$3
        RETENTION_MONTH=$4
        shift 3
      else
        echo "Error in -r|--retention syntax. Script failed."
        exit 1
      fi
      ;;

    -d|--dates)
      if [[ "$#" -gt 1 && ! "$2" = \-* && ! "$3" = \-* && ! "$3" == "" ]]; then
        MONTHLY_BACKUP_DATE=$2
        WEEKLY_BACKUP_DAY=$3
        shift 2
      else
        echo "Error in -d|--dates syntax. Script failed."
        exit 1
      fi
      ;;

    --)              # End of all options.
        shift
        break
        ;;

    -?*)
        printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
        ;;

    '') # Empty case: If no more options then break out of the loop.
        break
        ;;

    *)  # Anything unrecognized
        echo "The value "$1" was not expected. Script failed."
        exit 1
        ;;
  esac

  shift
done

EMAIL_SUBJECT_TAG="[backup of $SOURCE_DIR@$HOST]"

# STARTING BACKUP SCRIPT

# Set compression parameters

if [ "$COMPRESSION" == "lzma" ]; then
  tar_extension='.tar.xz'
  tar_options='-chJf'
elif [ "$COMPRESSION" == "gzip" ]; then
  tar_extension='.tar.gz'
  tar_options='-chzf'
else
  tar_extension=''
fi

#Check date

# Get current month and week day number
month_day=`date +"%d"`
week_day=`date +"%u"`

# On first month day do
  if [ "$month_day" -eq $MONTHLY_BACKUP_DATE ] ; then
    BACKUP_TYPE='-monthly'
    RETENTION_DAY_LOOKUP=$RETENTION_MONTH

    COMPARATOR=4
  else
  # On saturdays do
    if [ "$week_day" -eq $WEEKLY_BACKUP_DAY ] ; then
    # weekly - keep for RETENTION_WEEK
    BACKUP_TYPE='-weekly'
    RETENTION_DAY_LOOKUP=$RETENTION_WEEK

    COMPARATOR=2
  else
    # On any regular day do
      BACKUP_TYPE='-daily'
      RETENTION_DAY_LOOKUP=$RETENTION_DAY

      COMPARATOR=1
    fi
  fi

CURRENT_DIR=${PWD}

if [ ! $FTP_BACKUP_OPTION -eq 0 ]; then

  cd $CURRENT_DIR

  # get a list of all existing files of this type (daily,weekly or monthly)
  echo "user $FTP_USER $FTP_PASSWORD" > $TMP_DIR/ftp.backup.list.command.tmp
  echo "cd $FTP_TARGET_DIR" >> $TMP_DIR/ftp.backup.list.command.tmp
  echo "dir" >> $TMP_DIR/ftp.backup.list.command.tmp
  FTP_EXISTING_FILES=`ftp -n -v -p $FTP_HOST $FTP_PORT < $TMP_DIR/ftp.backup.list.command.tmp | grep -o "backup-.*\$BACKUP_TYPE.*"`
  rm $TMP_DIR/ftp.backup.list.command.tmp

fi

if [ ! $LOCAL_BACKUP_OPTION -eq 0 ]; then
  # Cleanup expired backups
  echo "Removing expired (local) backups..."
  find $TARGET_DIR/ -maxdepth 1 -mtime +$RETENTION_DAY_LOOKUP -name "*$BACKUP_TYPE*" -exec rm -rv {} \;
fi

PERFORM_SQL_BACKUP=0
PERFORM_FILES_BACKUP=0

# Check wheter to do backup
# This no longer is FTP or LOCAL
# but rather if the backup of the
# files should be SQL or FILES.
if [[ $(( $COMPARATOR & $SQL_BACKUP_OPTION )) == $COMPARATOR ]]; then
  PERFORM_SQL_BACKUP=1
fi

if [[ $(( $COMPARATOR & $FILES_BACKUP_OPTION )) == $COMPARATOR ]]; then
  PERFORM_FILES_BACKUP=1
fi

#This will force the backup to run immediately.
if [ $RUN_NOW -eq 1 ]; then
PERFORM_LOCAL_BACKUP=$LOCAL_BACKUP_OPTION
PERFORM_FTP_BACKUP=$FTP_BACKUP_OPTION
PERFORM_SQL_BACKUP=$SQL_BACKUP_OPTION
PERFORM_FILES_BACKUP=$FILES_BACKUP_OPTION
fi

echo "Creating backup dir.."

#Remove previous tmp dir
rm -rf $TMP_DIR/backup.incoming
mkdir -p $TMP_DIR/backup.incoming

# + I don't think we need to cd into there since it's specified via the command
#cd $TMP_DIR/backup.incoming

# Destination file names
base_backup_filename=backup-`date +"%Y-%m-%d"`$BACKUP_TYPE
backup_filename=$base_backup_filename''$tar_extension

# SQL section
if [ ! $PERFORM_SQL_BACKUP -eq 0 ]; then

  echo "Perform sql backup..."

  # Destination file names
  backup_filename=$base_backup_filename'.sql'$tar_extension
  
  backup_filename_sql=$backup_filename

  # Dump MySQL tables
  mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_DATABASE $EXTRA_MYSQLDUMP_OPTIONS > $TMP_DIR/backup.incoming/mysql_dump.sql

  if [ ! "$COMPRESSION" == "none" ]; then
      echo "Compress sql backup.."

      cd $TMP_DIR/backup.incoming
      tar $tar_options $backup_filename mysql_dump.sql

      #clean sql file
      cd $CURRENT_DIR
      rm $TMP_DIR/backup.incoming/mysql_dump.sql
  else
      cd $TMP_DIR/backup.incoming
      mv mysql_dump.sql $backup_filename
      cd $CURRENT_DIR
  fi
fi

cd $CURRENT_DIR

# + This doesn't seem to work right. Maybe it's in the wrong place or looking for the wrong thing.
# Even if backup works properly, this still generates an email saying that it failed.
#
# Optional check if source files exist. Email if failed.
#if [ ! -f $TMP_DIR/backup.incoming/$backup_filename ]; then
#  echo "Daily backup failed! Please check for missing files." | mail -s "$EMAIL_SUBJECT_TAG Backup Failed" $MAIL
#fi

# Perform Files Backup
if [ ! $PERFORM_FILES_BACKUP -eq 0 ]; then
  backup_filename=$base_backup_filename'.data'$tar_extension
  backup_filepath=$TMP_DIR/backup.incoming/$backup_filename

  if [ ! "$COMPRESSION" == "none" ]; then
      echo "Compress file backup..."

      # Compress files
      tar $tar_options $backup_filepath $SOURCE_DIR
  else
      # no compression: assume the source is a file that can be used directly
      backup_filepath=$SOURCE_DIR
  fi
fi

# FTP
if [ ! $FTP_BACKUP_OPTION -eq 0 ]; then
  echo "Copy backup to FTP.."

  echo "user $FTP_USER $FTP_PASSWORD" >> $TMP_DIR/backup.incoming/ftp_command.tmp
  echo "mkdir $FTP_TARGET_DIR" >> $TMP_DIR/backup.incoming/ftp_command.tmp
  echo "cd $FTP_TARGET_DIR" >> $TMP_DIR/backup.incoming/ftp_command.tmp
  echo "binary" >> $TMP_DIR/backup.incoming/ftp_command.tmp
  echo "put $backup_filepath $FTP_TARGET_DIR/$backup_filename" >> $TMP_DIR/backup.incoming/ftp_command.tmp
  
  if [ ! $PERFORM_SQL_BACKUP -eq 0 ]; then
    echo "put $TMP_DIR/backup.incoming/$backup_filename_sql $FTP_TARGET_DIR/$backup_filename_sql" >> $TMP_DIR/backup.incoming/ftp_command.tmp
  fi

  for f in $FTP_EXISTING_FILES; do
    date_of_file_str=`echo $f | sed -e s/backup-// -e "s/\$BACKUP_TYPE.*//"`
    date_of_file=`date --date="$date_of_file_str" "+%s"`
    old_date=`date --date="$RETENTION_DAY_LOOKUP days ago" "+%s"`
    if [ "$old_date" -gt "$date_of_file" ]; then
        echo "file outdated, deleting: $f"
        echo "delete $FTP_TARGET_DIR/$f" >>  $TMP_DIR/backup.incoming/ftp_command.tmp
    else
        echo "file recent enough ($date_of_file_str), keeping: $f"
    fi
  done
  echo "bye" >>  $TMP_DIR/backup.incoming/ftp_command.tmp

  ftp -n -v -p $FTP_HOST $FTP_PORT < $TMP_DIR/backup.incoming/ftp_command.tmp


  # +Randomly generate a number to reduse the chances of overwriting an existing file. Helps ensure we get a current list and not something possibly st
  FTP_RANDOM=$(( ( RANDOM % 100 )  + 1 ))
  # +Temp file to allow easy emailing of current list of backups.
  FTP_BACKUP_LIST=$TMP_DIR/ftp.backup.list.$FTP_RANDOM.txt
  touch $FTP_BACKUP_LIST
  echo "Sending mail"
  echo "FTP backup finished. Here's the current list of backups." > $FTP_BACKUP_LIST
  echo " " >> $FTP_BACKUP_LIST

  echo "user $FTP_USER $FTP_PASSWORD" >> $TMP_DIR/ftp.backup.list.command.tmp
  echo "cd $FTP_TARGET_DIR" >> $TMP_DIR/ftp.backup.list.command.tmp
  echo "dir" >> $TMP_DIR/ftp.backup.list.command.tmp
  ftp -n -v -p $FTP_HOST $FTP_PORT < $TMP_DIR/ftp.backup.list.command.tmp | grep backup >> $FTP_BACKUP_LIST

  cat $FTP_BACKUP_LIST | mail -s "$EMAIL_SUBJECT_TAG FTP backup finished !" $MAIL
  rm $TMP_DIR/ftp.backup.list.*
fi


#Perform local backup
if [ ! $LOCAL_BACKUP_OPTION -eq 0 ]; then

  if [ ! -d $TARGET_DIR ]; then
    echo "Target directory : '$TARGET_DIR/' doesn't exist.."
    echo "Target directory : '$TARGET_DIR/' doesn't exist.." | mail -s "$EMAIL_SUBJECT_TAG Failed !" $MAIL
    echo "Exiting..."
    exit
  fi

  # Move the files (just the sql in case of no compression)
  if [ "$(ls -A $TMP_DIR/backup.incoming/)" ]; then
      echo "Move backup to local dir.."
      mv -v $TMP_DIR/backup.incoming/* $TARGET_DIR
  fi

  # Copy source files if existing (if no compression)
  if [ -f $backup_filepath ]; then
      echo "Copy backup to local dir.."
      cp $backup_filepath $TARGET_DIR/$backup_filename
  fi

  # Optional check if source files exist. Email if failed.
  if [ -f $TARGET_DIR/$backup_filename ]; then
    # +Randomly generate a number to reduse the chances of overwriting an existing file. Helps ensure we get a current list and not something possibly stale.
    LOCAL_RANDOM=$(( ( RANDOM % 100 )  + 1 ))
    # +Temp file to allow easy emailing of current list of backups.
    LOCAL_BACKUP_LIST=$TMP_DIR/local.backup.list.$LOCAL_RANDOM.txt
    touch $LOCAL_BACKUP_LIST
    echo "Sending mail"
    echo "Local backup finished. Here's the current list of backups." > $LOCAL_BACKUP_LIST
    echo " " >> $LOCAL_BACKUP_LIST
    # +Sleep here to give the system a chance to catch up. If it goes to fast, the total size count could sometimes be incorrect.
    sleep 2
    ls -lah $TARGET_DIR >> $LOCAL_BACKUP_LIST
    cat $LOCAL_BACKUP_LIST | mail -s "$EMAIL_SUBJECT_TAG Local backup finished !" $MAIL
    rm $TMP_DIR/local.backup.list.*
  else
    echo "$TARGET_DIR/$backup_filename does not seem to exist. Something failed." | mail -s "$EMAIL_SUBJECT_TAG Finished, but failed." $MAIL
  fi
fi

#Remove tmp dir
rm -rf $TMP_DIR/backup.incoming

echo "Finish.."
