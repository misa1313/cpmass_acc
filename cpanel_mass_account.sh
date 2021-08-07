#! /bin/sh

#mramirez@liquidweb.com
#This script can be used to mass create templated cPanel accounts
#Requires a list of domains/accounts with one account per line
clear
echo -e "Please provide the path of the file containing the list of accounts, each listed with the following format:\n\ndomain.com username password \n\nNote: Only the domain name is mandatory, default values will be configured if no other information is specified.\n"
read path

#Loop to make sure file exists
while true; do
        if  [[ -f "$path" ]] ; then
            break
        else
            echo -e "File does not exists, please try again.\n"
            read path
        fi
done
echo -e "\n"

#To empty the log, if the file exists
if [[ -f "/root/execution_results.log" ]]; then
echo -n "" > /root/execution_results.log
fi

#Loop to create an account for each element in the list
count=1
sed -i  "/^ *$/d" $path #Remove empty lines from the file
lines=$(cat $path|wc -l)
while [[ $count -le $lines ]]
do
        data=$(cat $path|awk "NR==$count")
        data_array=($data)
        domain=$(echo ${data_array[0]})
        username=$(echo ${data_array[1]})
        password=$(echo ${data_array[2]})

        if [[ -z "$username" ]]; then
                u1=$(echo "$domain" |cut -c1-4|cut -d '.' -f1)
                username=$(echo "$u1$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 3 | head -n 1)") #To avoid errors with similar domains, using urandom to attach 3 random characters to the username
                echo -e "\nNo username, generating one: $username"
        fi

        (echo -e "- Domain: $domain\n"; whmapi1 createacct domain=$domain username=$username password=$password  --output=xml 2> /dev/null; echo -e "\n") >> /root/execution_results.log
        results=$(grep "result" /root/execution_results.log|tail -n1)
        reason=$(grep "reason" /root/execution_results.log |tail -n1)
	reason=$(echo $reason|cut -d '>' -f2|cut -d '<' -f1)
	if [[ "$results" == *"1"* ]]; then
                echo "- Account $username for domain $domain, has been created successfully."
        else
                echo -e "Failed, there was an error during the account creation for domain $domain. Reason $reason"
        fi
(( count++ ))
done

echo -e "\nA log of this operation was saved at /root/execution_results.log"

