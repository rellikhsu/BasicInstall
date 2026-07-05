# BasicInstall

新機器開機後的基本環境初始化腳本（bootstrap installer）。在乾淨安裝的系統上以 root 執行一次，完成套件安裝與基本設定。

## 檔案結構

- `Debian/Debian13-installer.sh`：Debian 13 (trixie) 初始化腳本

（CentOS 7 與 Debian 9/10/11 腳本已因發行版 EOL 移除，需要時可從 git history 取回。）

## Debian13-installer.sh 做的事

1. **APT sources**：寫入 deb822 格式的 `/etc/apt/sources.list.d/debian.sources`，使用 `deb.debian.org`，Components 含 `main contrib non-free non-free-firmware`
2. **套件安裝**：常用系統工具（見腳本內 `INST_PACKAGE_LIST`）
3. **時區**：Asia/Taipei
4. **時間同步**：停用 systemd-timesyncd，改用 chrony；NTS 來源（Cloudflare、Netnod）+ Google NTP fallback，開機初期允許 step 校時
5. **Locale**：en_US.UTF-8 / zh_TW.UTF-8
6. **sysctl**：`vm.swappiness = 1`（`/etc/sysctl.d/99-local.conf`）
7. **使用者環境範本**：寫入 `/etc/skel/` 的 `.bashrc`、`.screenrc`、`.vimrc`（PS1、alias、screen/vim 設定）

## 使用方式

```bash
# 於乾淨安裝的 Debian 13 上以 root 執行
bash Debian/Debian13-installer.sh
```

注意：腳本為 `set -euo pipefail`，任一步驟失敗即中止；`/etc/skel/` 的設定只影響之後新建的使用者。
