FROM python:3.5.2
###Update sources
RUN echo "deb http://mirrors.163.com/debian/ jessie main non-free contrib" > /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/debian/ jessie-updates main non-free contrib" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/debian/ jessie-backports main non-free contrib" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/debian-security/ jessie/updates main non-free contrib" >> /etc/apt/sources.list

###Install openssh-server
ENV AUTHORIZED_KEY "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAinL3rFGOl9WwXEgFsIGWpPU10N7UeHf4NMgCm2Qaz5jx323Mf/s1O4FrvkirSerdkWo4a+8R+lIRVqCHpnsVSrzxzlNim2+uKr57T8jDDmNcGT7lO4URWtL4bsBCFEQx1ZpaeCY+ilyIorc6bVDog4EEOuLJPsQWlcEJ7aW8cFw3Q6+7ogbnvo2rz9wRvWn05VBG0itmE1D+gXwgWGNzgLMqWnTpcdwFmS4RJamT79pQcIKhqzwdUszBCPt9/MXXjyZytq1mjFJp9reNx1V3ms+D7WbRUIBuiJ/Bm1uL/7X1tU0Q1GJdNGzPJ8jFcb/+uzNbzWq3JwXA0jL69k1qOw=="
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir -p /var/run/sshd
###Public key authentication
RUN mkdir -p /root/.ssh
RUN chmod 600 /root/.ssh
RUN touch /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys
RUN echo "$AUTHORIZED_KEY" >> /root/.ssh/authorized_keys
RUN sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config
# RUN sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
###Username/Password authentication
RUN sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
RUN echo "root:root@admin" | chpasswd
###Expose 22 for SSH access
EXPOSE 22
###Expose 80 for Django
EXPOSE 80
###Install APP
RUN apt-get install -y nginx supervisor
###RUN pip install uwsgi
RUN pip install uwsgi -i http://pypi.douban.com/simple --trusted-host pypi.douban.com
RUN rm /etc/nginx/sites-enabled/default
ADD nginx.conf /etc/nginx/sites-enabled/
ADD uwsgi.ini /etc/uwsgi/
ADD supervisord.conf /etc/supervisor/conf.d
###ADD Local app
RUN mkdir /code
ADD requirements.txt /code
RUN pip install -r /code/requirements.txt -i http://pypi.douban.com/simple --trusted-host pypi.douban.com
ADD ./example_app /code
VOLUME /code
WORKDIR /code
ENTRYPOINT bash -c "python manage.py collectstatic --noinput && service nginx start && uwsgi --ini /etc/uwsgi/uwsgi.ini && /usr/sbin/sshd -D"
###docker run -v
# ENTRYPOINT bash -c "pip install -r /code/requirements.txt -i http://pypi.douban.com/simple --trusted-host pypi.douban.com  && service nginx start && uwsgi --ini /etc/uwsgi/uwsgi.ini && /usr/sbin/sshd -D"
