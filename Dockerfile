FROM python:3.5.2
ENV deb_sources http://ftp.jp.debian.org
ENV pip_sources https://pypi.python.org/pypi/simple
ENV deb_sources http://mirrors.163.com
ENV pip_sources https://pypi.doubanio.com/simple/
# Update sources
RUN echo "deb $deb_sources/debian/ jessie main non-free contrib" > /etc/apt/sources.list &&\
	echo "deb $deb_sources/debian/ jessie-updates main non-free contrib" >> /etc/apt/sources.list &&\
	echo "deb $deb_sources/debian/ jessie-backports main non-free contrib" >> /etc/apt/sources.list &&\
	echo "deb $deb_sources/debian-security/ jessie/updates main non-free contrib" >> /etc/apt/sources.list

# Install openssh-server
ENV AUTHORIZED_KEY "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAinL3rFGOl9WwXEgFsIGWpPU10N7UeHf4NMgCm2Qaz5jx323Mf/s1O4FrvkirSerdkWo4a+8R+lIRVqCHpnsVSrzxzlNim2+uKr57T8jDDmNcGT7lO4URWtL4bsBCFEQx1ZpaeCY+ilyIorc6bVDog4EEOuLJPsQWlcEJ7aW8cFw3Q6+7ogbnvo2rz9wRvWn05VBG0itmE1D+gXwgWGNzgLMqWnTpcdwFmS4RJamT79pQcIKhqzwdUszBCPt9/MXXjyZytq1mjFJp9reNx1V3ms+D7WbRUIBuiJ/Bm1uL/7X1tU0Q1GJdNGzPJ8jFcb/+uzNbzWq3JwXA0jL69k1qOw=="
RUN apt-get update && apt-get install -y openssh-server && mkdir -p /var/run/sshd
## Public key authentication
RUN mkdir -p /root/.ssh &&\
	chmod 600 /root/.ssh &&\
	touch /root/.ssh/authorized_keys &&\
	chmod 600 /root/.ssh/authorized_keys &&\
	echo "$AUTHORIZED_KEY" >> /root/.ssh/authorized_keys
	
## Username/Password authentication
RUN echo "root:root@admin" | chpasswd

RUN sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config &&\
	#sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config &&\
	sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config

# Install runtime environment
RUN apt-get install -y nginx supervisor &&\
	rm /etc/nginx/sites-enabled/default &&\
	sed -i.bak '/worker_processes/a daemon off;' /etc/nginx/nginx.conf
RUN pip install uwsgi -i $pip_sources
ADD nginx.conf /etc/nginx/sites-enabled/
ADD uwsgi.ini /etc/uwsgi/
ADD supervisord.conf /etc/supervisor/conf.d

# ADD app
ADD ./example_app /code
RUN pip install -r /code/requirements.txt -i $pip_sources
VOLUME /code
WORKDIR /code

# Expose 22 for SSH access && Expose 80 for WEB
EXPOSE 22 80

ENTRYPOINT bash -c "pip install -r /code/requirements.txt -i $pip_sources && /usr/bin/supervisord"
#ENTRYPOINT bash -c "service nginx start && uwsgi --ini /etc/uwsgi/uwsgi.ini && /usr/sbin/sshd -D"
#ENTRYPOINT bash -c "pip install -r /code/requirements.txt -i $pip_sources  && service nginx start && uwsgi --ini /etc/uwsgi/uwsgi.ini && /usr/sbin/sshd -D"