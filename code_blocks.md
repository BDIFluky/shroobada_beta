## Table of Contents
- [Grant sudo Privileges](#grant-sudo-privileges)

## Grant sudo Privileges
This has to be done as a sudoer able to exeute the required commands, or as root.
<table align="center">
  <thead>
  <tr>
    <td align="center" weight: bold>Sudo Group</td><td align="center" weight: bold>Sudoers File</td>
  </tr>
      </thead>
  <tbody>
  <tr>

  <td>
      
  ```bash

  # append user to group
  usermod -a [UserName] -G sudo 
  ```
      
  </td>

  <td>
  
  ```bash

  # append line after root line
  sed -ri 's/(root(.*ALL:ALL.*))/\1\n[UserName]\2/' /etc/sudoers
  ```
  </td>
  </tr>
  </tbody>
</table>
