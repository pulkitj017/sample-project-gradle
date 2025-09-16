sudo apt update
sudo apt install openjdk-8-jdk -y
wget https://services.gradle.org/distributions/gradle-6.8.1-bin.zip
sudo apt install unzip -y
unzip gradle-6.8.1-bin.zip
sudo mv gradle-6.8.1 /opt/gradle
echo "export PATH=\$PATH:/opt/gradle/bin" >> ~/.bashrc
source ~/.bashrc
gradle -v
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:openjdk-r/ppa -y
bash ./gradlew dependencyUpdates > outdated.txt
bash ./gradlew generateLicenseReport