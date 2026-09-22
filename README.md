# Vulnerable-AD-AI

## 📖 Description

**Vulnerable-AD-AI** is a vulnerable Active Directory environment created with the assistance of Artificial Intelligence. This project provides a set of PowerShell scripts to automatically deploy a Windows Server lab with an intentionally misconfigured Active Directory, designed for cybersecurity training, penetration testing practice, and educational purposes.

The environment includes common AD vulnerabilities and misconfigurations, making it an ideal target for practicing attack techniques such as Kerberoasting, AS-REP Roasting, ACL abuse, delegation attacks, and more.

> ⚠️ **WARNING:** This project is for **educational purposes only**. Do not deploy in production or any environment connected to the internet. Use only in isolated lab networks.

---

## 🚀 Features

- Fully automated AD lab deployment using PowerShell scripts
- Step-by-step scripts for server preparation, domain creation, AD configuration, and vulnerability injection
- Includes verification scripts to confirm vulnerabilities are present
- CTF-style setup with flags and challenges
- `run_all.ps1` script to execute the entire deployment in one go
- Detailed instructions in `Instrucciones.txt` (Spanish)

---

## 📂 Project Structure

| File | Description |
|------|-------------|
| `00_renombre_servidor.ps1` | Renames the server to a suitable name for the lab. |
| `01_preparacion_servidor.ps1` | Prepares the server: installs required roles and features. |
| `02_creacion_dominio.ps1` | Creates a new Active Directory forest and promotes the server to a Domain Controller. |
| `03_configuracion_ad.ps1` | Configures AD: creates OUs, users, groups, and basic structure. |
| `04_crear_vulnerabilidades.ps1` | Introduces intentional vulnerabilities and misconfigurations. |
| `05_verificar_vulnerabilidades.ps1` | Verifies that the vulnerabilities have been successfully created. |
| `06_ctf_setup.ps1` | Sets up CTF elements such as flags and challenge files. |
| `Instrucciones.txt` | Detailed step-by-step instructions (in Spanish). |
| `run_all.ps1` | Executes all scripts in the correct order. |
| `README.md` | This file. |

---

## 🛠️ Requirements

- **Windows Server** (2016, 2019, or 2022 recommended)
- **PowerShell** with administrative privileges
- A virtual machine or isolated lab environment (VMware, VirtualBox, Hyper-V, etc.)
- No internet connection required during execution (recommended)

---

## ⚙️ Usage

1. **Clone the repository:**
   ```bash
   git clone https://github.com/akthanon/Vulnerable-AD-AI.git
   cd Vulnerable-AD-AI
   ```

2. **Transfer the scripts to your Windows Server VM.**

3. **Open PowerShell as Administrator.**

4. **Set the execution policy (if needed):**
   ```powershell
   Set-ExecutionPolicy Unrestricted -Scope Process -Force
   ```

5. **Run the entire setup:**
   ```powershell
   .\run_all.ps1
   ```

   Or run the scripts individually in numerical order:
   ```powershell
   .\00_renombre_servidor.ps1
   .\01_preparacion_servidor.ps1
   .\02_creacion_dominio.ps1
   .\03_configuracion_ad.ps1
   .\04_crear_vulnerabilidades.ps1
   .\05_verificar_vulnerabilidades.ps1
   .\06_ctf_setup.ps1
   ```

6. **Follow the detailed instructions in `Instrucciones.txt` for additional configuration and troubleshooting.**

> **Note:** Some scripts may require a reboot or re-logon to take effect.

---

## ⚠️ Security Warning

This environment contains **intentional vulnerabilities** that can compromise the system. It must be used **only** in an isolated lab network with no connection to production systems or the internet. The authors are not responsible for any misuse or damage caused by this project.

---

## 🎯 Educational Objectives

- Understand how Active Directory works and how it can be misconfigured.
- Practice offensive techniques against AD in a safe, controlled environment.
- Learn to identify and exploit common AD vulnerabilities.
- Develop defensive skills by understanding how these vulnerabilities are created and how to remediate them.

---

## 🤝 Contributions

Contributions are welcome! If you have suggestions for new vulnerabilities, improvements, or fixes, please open an issue or submit a pull request.

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

## 📜 License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## 📞 Contact

- **GitHub:** [@akthanon](https://github.com/akthanon)
- **Issues:** [Report a bug](https://github.com/akthanon/Vulnerable-AD-AI/issues)

---

**Created with ❤️ and AI for the offensive security community.**
