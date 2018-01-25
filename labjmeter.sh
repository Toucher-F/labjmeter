#!/bin bash

function top
{
    grep load /labjmeter/${FOLDERNAME}/${1}-top-${FOLDERNAME} | awk  '{print $3 "\t" $10"\t" $11"\t" $12}' > /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/top1
    if grep -niwq "load" /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/top1; then
        rm /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/top1
        grep load /labjmeter/${FOLDERNAME}/${1}-top-${FOLDERNAME} | awk  '{print $3 "\t" $12"\t" $13"\t" $14}' > /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/top1
    fi
    grep Tasks /labjmeter/${FOLDERNAME}/${1}-top-${FOLDERNAME} | awk  '{print $4}' > /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/top2
    grep Cpu /labjmeter/${FOLDERNAME}/${1}-top-${FOLDERNAME}  > /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/top3
    awk '{for(i=2;i<=NF;i=i+2) printf"%s ",$i} {print ""}' /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/top3 > /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/top4
    grep cache /labjmeter/${FOLDERNAME}/${1}-top-${FOLDERNAME} | awk  '{print $4 "\t" $6"\t"}' > /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/top5
    grep vda /labjmeter/${FOLDERNAME}/${1}-io-${FOLDERNAME} | awk '{print $9 "\t" $10"\t" $13"\t" $14}' > /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/io1
    paste /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/top1 /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/top2 /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/top4 /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/top5 /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/io1 > /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-${1}-top-${FOLDERNAME}
    sed -i 's/^/'${CONCURRENCY}' '${1}' &/g' /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-${1}-top-${FOLDERNAME}
    #sed -i 's/$/&'${DIRNAME}'/g' /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-app1-top-${FOLDERNAME}
    sed -i '1i\Concurrency server time LOADavg1m LOADavg5m LOADavg15m Tasks us sy ni id wa hi si st MEMtotal MEMfree avgqu-sz await svctm util' /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-${1}-top-${FOLDERNAME}
    rm /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/top* /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/io*
}

#read -p "Please input the case type[api/full/other]?" CASETYPE
#if [ -z ${CASETYPE} ];then
#	echo "The case type cannot be null"
#	exit 1
#fi
#arr=(api full)
#arr2=(other)
#if
#	echo ${arr[@]} | grep -wq ${CASETYPE}
#then
#    read -p "Please input the project concurrency?" CONCURRENCY
#    if [ -z ${CONCURRENCY} ];then
#	    echo "The concurrency cannot be null"
#	    exit 1
#    else
#        CASENAME=${CASETYPE}-30prod-${CONCURRENCY}.jmx
#    fi
#elif
#	echo ${arr2[@]} | grep -wq ${CASETYPE}
#then
    read -p "Please input the case name?" CASENAME
    if [ -z ${CASENAME} ];then
	echo "The case name cannot be null"
	exit 1
    fi
    read -p "Please input the project concurrency?" CONCURRENCY
    if [ -z ${CONCURRENCY} ];then
	    echo "The concurrency cannot be null"
	    exit 1
    fi
#else
#    echo "invalid case type"
#	exit 1
#fi

if [ ! -f "/jmeter/apache-jmeter-3.1/bin/${CASENAME}" ]; then
    echo "invalid case name"
	exit 1
else
    echo "" >/dev/null
fi

read -p "Please input the name of recipient [tracy/wei/simin/fei]?" RECIPIENT
if [ -z ${RECIPIENT} ];then
	echo "The recipient cannot be null"
	exit 1
fi
arr3=(tracy wei simin fei bill)
if
	echo ${arr3[@]} | grep -wq ${RECIPIENT}
then
    echo "" >/dev/null
else
	echo "The recipient is invalid"
	exit 1
fi


DIRNAME=${CASENAME}_$(date +"%Y%m%d%H%M%S")
mkdir /labjmeter/${DIRNAME}

echo "------------------creating log file-----------------"
ssh -o StrictHostKeyChecking=no root@10.137.160.212 "touch /storage/app1-top-${DIRNAME} && nohup top -u 1 -b > /storage/app1-top-${DIRNAME} &" &
#ssh -o StrictHostKeyChecking=no root@10.137.144.173 "touch /storage/app2-top-${DIRNAME} && nohup top -u 1 -b > /storage/app2-top-${DIRNAME} &" &
#ssh -o StrictHostKeyChecking=no root@10.137.48.137 "touch /storage/pg-top-${DIRNAME} && nohup top -u 1 -b > /storage/pg-top-${DIRNAME} & " &

ssh -o StrictHostKeyChecking=no root@10.137.160.212 "touch /storage/app1-io-${DIRNAME} && iostat 3 -x > /storage/app1-io-${DIRNAME} &" &
#ssh -o StrictHostKeyChecking=no root@10.137.144.173 "touch /storage/app2-io-${DIRNAME} && iostat 3 -x > /storage/app2-io-${DIRNAME} &" &
#ssh -o StrictHostKeyChecking=no root@10.137.48.137 "touch /storage/pg-io-${DIRNAME} && iostat 3 -x > /storage/pg-io-${DIRNAME} & " &

echo "------------------running test case-----------------"


cd /jmeter/apache-jmeter-3.1/bin && ./jmeter -n -t $CASENAME -l /labjmeter/${DIRNAME}/${DIRNAME}.csv

echo "------------------terminating top proccess-----------------"

#APP1TOP=$(ssh -o StrictHostKeyChecking=no root@10.137.160.212 "ps -ef | grep "top" | grep -v "grep" | awk '{print \$2}'")
#APP2TOP=$(ssh -o StrictHostKeyChecking=no root@10.137.144.173 "ps -ef | grep "top" | grep -v "grep" | awk '{print \$2}'")
#PGTOP=$(ssh -o StrictHostKeyChecking=no root@10.137.48.137 "ps -ef | grep "top" | grep -v "grep" | awk '{print \$2}'")
#ssh -o StrictHostKeyChecking=no root@10.137.160.212 "kill -9 ${APP1TOP}"
#ssh -o StrictHostKeyChecking=no root@10.137.144.173 "kill -9 ${APP2TOP}"
#ssh -o StrictHostKeyChecking=no root@10.137.48.137 "kill -9 ${PGTOP}"
APP1TOP=$(ssh -o StrictHostKeyChecking=no root@10.137.160.212 "ps -ef | grep "top" | grep -v "grep" | awk '{print \$2}' | xargs kill -9")
#APP2TOP=$(ssh -o StrictHostKeyChecking=no root@10.137.144.173 "ps -ef | grep "top" | grep -v "grep" | awk '{print \$2}' | xargs kill -9")
#PGTOP=$(ssh -o StrictHostKeyChecking=no root@10.137.48.137 "ps -ef | grep "top" | grep -v "grep" | awk '{print \$2}' | xargs kill -9")

echo "------------------terminating iostat proccess-----------------"
APP1TOP=$(ssh -o StrictHostKeyChecking=no root@10.137.160.212 "ps -ef | grep "iostat" | grep -v "grep" | awk '{print \$2}' | xargs kill -9")
#APP2TOP=$(ssh -o StrictHostKeyChecking=no root@10.137.144.173 "ps -ef | grep "iostat" | grep -v "grep" | awk '{print \$2}' | xargs kill -9")
#PGTOP=$(ssh -o StrictHostKeyChecking=no root@10.137.48.137 "ps -ef | grep "iostat" | grep -v "grep" | awk '{print \$2}' | xargs kill -9")


echo "------------------copying file-----------------"

scp -r root@10.137.160.212:/storage/app1-top-${DIRNAME} /labjmeter/${DIRNAME}/
#scp -r root@10.137.144.173:/storage/app2-top-${DIRNAME} /labjmeter/${DIRNAME}/
#scp -r root@10.137.48.137:/storage/pg-top-${DIRNAME} /labjmeter/${DIRNAME}/

scp -r root@10.137.160.212:/storage/app1-io-${DIRNAME} /labjmeter/${DIRNAME}/
#scp -r root@10.137.144.173:/storage/app2-io-${DIRNAME} /labjmeter/${DIRNAME}/
#scp -r root@10.137.48.137:/storage/pg-io-${DIRNAME} /labjmeter/${DIRNAME}/

ssh -o StrictHostKeyChecking=no root@10.137.160.212 "rm /storage/app1-top-${DIRNAME}"
#ssh -o StrictHostKeyChecking=no root@10.137.144.173 "rm /storage/app2-top-${DIRNAME}"
#ssh -o StrictHostKeyChecking=no root@10.137.48.137 "rm /storage/pg-top-${DIRNAME}"

ssh -o StrictHostKeyChecking=no root@10.137.160.212 "rm /storage/app1-io-${DIRNAME}"
#ssh -o StrictHostKeyChecking=no root@10.137.144.173 "rm /storage/app2-io-${DIRNAME}"
#ssh -o StrictHostKeyChecking=no root@10.137.48.137 "rm /storage/pg-io-${DIRNAME}"



FOLDERNAME=${DIRNAME}

DIRNAME2=$(echo ${FOLDERNAME} | cut -d . -f 1)

if [ ! -d /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/ ];then
    mkdir /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/
fi
echo "=====================app1 start===================="
top app1
echo "=====================app1 end===================="
#if [ -f "/labjmeter/${FOLDERNAME}/app2-top-${FOLDERNAME}" ];then
#    echo "=====================app2 start===================="
#    top app2
#    echo "=====================app2 end===================="
#else
#    echo "=====================no app2===================="
#fi

#echo "=====================pg start===================="
#top pg
#echo "=====================pg end===================="

#if [ -f "/labjmeter/${FOLDERNAME}/app2-top-${FOLDERNAME}" ];then
#    cat /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-app1-top-${FOLDERNAME} /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-app2-top-${FOLDERNAME} /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-pg-top-${FOLDERNAME} > /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-final-${FOLDERNAME}
#else
    cat /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-app1-top-${FOLDERNAME} > /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-final-${FOLDERNAME}
#fi
echo "=====================sending email===================="
#echo "teststaging CSV ${FOLDERNAME}, sent from jmeter server" | mail -s "teststaging CSV ${FOLDERNAME}" -A /labjmeter/${FOLDERNAME}/${FOLDERNAME}.csv -c "wei.tian@newjobclub.com simin.chen@newjobclub.com fei.zhao@newjobclub.com" tracy.wang@saninco.com
#echo "teststaging result ${FOLDERNAME}, sent from jmeter server" | mail -s "teststaging result ${FOLDERNAME}" -A /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-final-${FOLDERNAME} -c "wei.tian@newjobclub.com simin.chen@newjobclub.com fei.zhao@newjobclub.com" tracy.wang@saninco.com
case $RECIPIENT in
	"tracy")
            echo "teststaging CSV ${FOLDERNAME}, sent from jmeter server" | mail -s "teststaging CSV ${FOLDERNAME}" -A /labjmeter/${FOLDERNAME}/${FOLDERNAME}.csv tracy.wang@saninco.com
            echo "teststaging result ${FOLDERNAME}, sent from jmeter server" | mail -s "teststaging result ${FOLDERNAME}" -A /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-final-${FOLDERNAME} tracy.wang@saninco.com
    ;;
 	"wei")
            echo "teststaging CSV ${FOLDERNAME}, sent from jmeter server" | mail -s "teststaging CSV ${FOLDERNAME}" -A /labjmeter/${FOLDERNAME}/${FOLDERNAME}.csv wei.tian@newjobclub.com
            echo "teststaging result ${FOLDERNAME}, sent from jmeter server" | mail -s "teststaging result ${FOLDERNAME}" -A /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-final-${FOLDERNAME} wei.tian@newjobclub.com
    ;;
 	"simin")
            echo "teststaging CSV ${FOLDERNAME}, sent from jmeter server" | mail -s "teststaging CSV ${FOLDERNAME}" -A /labjmeter/${FOLDERNAME}/${FOLDERNAME}.csv simin.chen@newjobclub.com
            echo "teststaging result ${FOLDERNAME}, sent from jmeter server" | mail -s "teststaging result ${FOLDERNAME}" -A /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-final-${FOLDERNAME} simin.chen@newjobclub.com
    ;;
 	"fei")
            echo "teststaging CSV ${FOLDERNAME}, sent from jmeter server" | mail -s "teststaging CSV ${FOLDERNAME}" -A /labjmeter/${FOLDERNAME}/${FOLDERNAME}.csv fei.zhao@newjobclub.com
            echo "teststaging result ${FOLDERNAME}, sent from jmeter server" | mail -s "teststaging result ${FOLDERNAME}" -A /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-final-${FOLDERNAME} fei.zhao@newjobclub.com
    ;;
 	"bill")
            echo "teststaging CSV ${FOLDERNAME}, sent from jmeter server" | mail -s "teststaging CSV ${FOLDERNAME}" -A /labjmeter/${FOLDERNAME}/${FOLDERNAME}.csv bill.duan@saninco.com
            echo "teststaging result ${FOLDERNAME}, sent from jmeter server" | mail -s "teststaging result ${FOLDERNAME}" -A /labjmeter/${FOLDERNAME}/result_${FOLDERNAME}/result-final-${FOLDERNAME} bill.duan@saninco.com
    ;;
	*)

		echo "please reset"
		;;
esac


echo "=====================moving file===================="
if [ ! -d "/labjmeter/history" ]; then
  mkdir /labjmeter/history
fi
mv /labjmeter/${DIRNAME} /labjmeter/history/
echo "--------------------end of labjmeter.sh----------------"