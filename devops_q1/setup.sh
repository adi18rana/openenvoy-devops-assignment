#!/bin/bash
set -e

# Update and install dependencies
yum update -y
yum install -y python3 python3-pip nginx

# Upgrade pip
pip3 install --upgrade pip

# Create app directory
APP_DIR="/opt/flaskapp"
mkdir -p $APP_DIR

# Setup Python virtual environment and install dependencies
python3 -m venv $APP_DIR/venv
source $APP_DIR/venv/bin/activate
pip install -r $APP_DIR/requirements.txt
deactivate

# systemd service file for Gunicorn
cat > /etc/systemd/system/flaskapp.service <<EOF
[Unit]
Description=Gunicorn instance to serve Flask app
After=network.target

[Service]
User=root
Group=root
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/venv/bin"
ExecStart=$APP_DIR/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 app:app

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable flaskapp
systemctl start flaskapp

# Setup Nginx reverse proxy
cat > /etc/nginx/conf.d/flaskapp.conf <<EOL
server {
    listen 80;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Restart nginx service
systemctl restart nginx
