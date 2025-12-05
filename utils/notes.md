# Standalone installation
andreibuhaiu@gmsil.com
## 1.1 [Optional] Target LLM-app
- Current repo is `prompt injection playground`
- Change the directory to the parent folder
- Clone `llm-webmail` repo
- Copy API keys
- Configure local DNS
- Create a virtual environment
- Install required libraries (e.g., transformers) 
- Change back the directory to the current git repo (prompt injection playground)
- `deactivate` the virtual environment

```jupyter

current_repo = !pwd
repo_root = !git rev-parse --show-toplevel
%cd {repo_root[0]}/..
!pwd

#git clone https://github.com/ReversecLabs/llm-webmail.git
git clone https://github.com/beyefendi/llm-webmail.git
%cd llm-webmail

# Copy API keys
cp {current_repo[0]}/.env-llm-webmail .env

# Update /etc/hosts file manually
# sudo nano /etc/hosts
# Add the following line to the hosts file
# 127.0.0.1   llmwebmail

# Install dependencies and set up virtual environment
make setup

# Run the Flask application
make run
!deactivate

```


## 1.2 Tools
- Current repo is `prompt injection playground`
- Change the directory to the parent folder
- Clone `spikee` repo
- Create a virtual environment
- Install required libraries (e.g., transformers) 
- Change back the directory to the current git repo (prompt injection playground)


```
current_repo = !pwd
repo_root = !git rev-parse --show-toplevel
%cd {repo_root[0]}/..
!pwd
!git clone https://github.com/ReversecLabs/spikee.git
%cd spikee
!python3 -m venv .venv-spikee
!source .venv-spikee/bin/activate
!pip install .
%cd {current_repo[0]}
```