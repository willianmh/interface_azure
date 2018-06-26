# remove last character
sed 's/.$//'

# remove between two characters
sed 's/["][^"]*["]//g;'

# remove first line
sed '1d'

# get first column
sed 's/,.*//'

# get second column
sed 's/[^,]*,\([^,]*\).*/\1/'

# remove especial characters
sed 's/[^a-zA-Z0-9]//g'

# to lower case
sed 's/./\L&/g'

# remove until @
sed 's/^.*@//'

# remove after @
sed 's/[@].*$//'
