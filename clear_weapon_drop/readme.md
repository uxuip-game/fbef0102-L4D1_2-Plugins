# Description | 內容
Remove weapon dropped by survivor or uncommon infected + remove upgrade pack when deployed

* Apply to | 適用於
	```
	L4D1
	L4D2
	```

* <details><summary>How does it work?</summary>

	* When weapons/items dropped by survivor or by uncommon infected.
		* If no one pick up weapons or items, they will be removed after the certain time passed
		* Will not remove Scavenge Gascan/cola/gnome.
	* When surivior deployed upgrade packs on the gound.
		* They will be removed after the certain time passed
	* Modify weapon/item delete list
		* [scripting/clear_weapon_drop.sp line 92~125](scripting/clear_weapon_drop.sp#L92-L125)
</details>

* Require | 必要安裝
<br/>None

* <details><summary>Related Plugin | 相關插件</summary>

	1. [l4d_drop](/l4d_drop): Allows players to drop the weapon they are holding
		> 玩家可自行丟棄手中的武器
</details>

* <details><summary>ConVar | 指令</summary>

	* cfg/sourcemod/clear_weapon_drop.cfg
		```php
		// Time in seconds to remove weapon after dropped by survivor. (0=off)
		sm_drop_clear_survivor_weapon_time "60"

		// Time in seconds to remove weapon after dropped by uncommon infected. (0=off)
		sm_drop_clear_infected_weapon_time "180"

		// Time in seconds to remove upgrade pack after deployed on the ground. (0=off)
		sm_drop_clear_ground_upgrade_pack_time "60"

		// If 1, remove gnome after dropped by survivor.
		sm_drop_clear_survivor_weapon_gnome "0"

		// If 1, remove cola bottles after dropped by survivor.
		sm_drop_clear_survivor_weapon_cola_bottles "0"
		```
</details>

* <details><summary>API | 串接</summary>

	```c
	/**
	* @brief Remove weapon if no one picks up after a short time. (time depending on the convar you set)
	*
	* @param weapon        weapon index to be removed
	*
	* @return              nothing
	*/
	native void Timer_Delete_Weapon(int weapon);
	```
</details>

* <details><summary>Changelog | 版本日誌</summary>

	* v3.2 (2025-1-30)
		* Optimize code

	* v3.1 (2023-5-10)
		* Will not remove Scavenge Gascan.
		* Optimize code and improve performance

	* v3.0 (2023-1-28)
		* Remove weapon after dropped by uncommon infected.

	* v2.9
		* [AlliedModder Post](https://forums.alliedmods.net/showpost.php?p=2731634&postcount=19)
		* Remake Code
		* Remove gnome and cola
		* Create Native
		* Use EntIndexToEntRef and EntRefToEntIndex to remove entity safely
		* Remove upgrade pack after deployed on the ground

	* v1.7
		* [Original Plugin by AK978](https://forums.alliedmods.net/showthread.php?p=2638375)
</details>

- - - -
# 中文說明
如果一段時間後沒有人撿起掉落的武器與物品，則自動移除

* 原理
    * 當人類從手上掉落物器或物品時，一段時間過後如果沒有人撿起或者使用將自動移除
		* 玩家死亡、丟棄、更換武器與物品
		* 玩家從手中丟出汽油桶、瓦斯桶、氧氣罐、煙火盒、精靈小矮人、可樂瓶也算 (不會移除黃色與綠色的汽油桶)
	* 當人類放置燃燒彈包與高爆彈包於地上之後，一段時間過後將自動移除
    * 當特殊一般感染者掉落武器或物品時，一段時間過後如果沒有人撿起或者使用將自動移除
		* CEDA防疫人員的膽汁瓶
		* 防暴警察的警棍
		* 墮落生還者的醫療與投擲物品
	* 不影響地圖上原本的武器與物品，只有當武器與物品從人類或者感染者身上掉落之後才會觸發移除

* 用意在哪?
	* 避免伺服器塞滿過多的武器與物品導致崩潰 (伺服器實體物件空間不足)
    * 適合用於很多RPG或頻繁生出武器與物品的伺服器

* <details><summary>指令中文介紹 (點我展開)</summary>

	* cfg/sourcemod/clear_weapon_drop.cfg
		```php
		// 人類從手上掉落物器或物品時，一段時間過後如果沒有人撿起或者使用將自動移除 (0=不移除)
		sm_drop_clear_survivor_weapon_time "60"

		// 當特殊一般感染者掉落武器或物品時，一段時間過後如果沒有人撿起或者使用將自動移除 (0=不移除)
		sm_drop_clear_infected_weapon_time "180"

		// 人類放置燃燒彈包與高爆彈包於地上. X秒之後移除 (0=不移除)
		sm_drop_clear_ground_upgrade_pack_time "60"

		// 為1時，刪除掉落的精靈小矮人
		sm_drop_clear_survivor_weapon_gnome "0"

		// 為1時，刪除掉落的可樂瓶
		sm_drop_clear_survivor_weapon_cola_bottles "0"
		```
</details>

* 修改武器與物品刪除的列表
	* [scripting/clear_weapon_drop.sp line 92~125](scripting/clear_weapon_drop.sp#L92-L125)
	* 修改完後重新編譯

    * 所有武器與物品名稱
		```php
		手槍 => weapon_pistol
		麥格農手槍 => weapon_pistol_magnum
		木製單發散彈槍 => weapon_pumpshotgun
		鐵製單發散彈槍 => weapon_shotgun_chrome
		Uzi烏茲衝鋒槍 => weapon_smg
		消音衝鋒槍 => weapon_smg_silenced
		自動連發散彈槍 => weapon_autoshotgun
		自動連發戰鬥散彈槍=> weapon_shotgun_spas
		獵槍 => weapon_hunting_rifle
		軍用狙擊槍 => weapon_sniper_military
		Uzi烏茲衝鋒槍 => weapon_smg
		M16步槍 => weapon_rifle
		三連發步槍 => weapon_rifle_desert
		AK47 => weapon_rifle_ak47
		榴彈發射器 => weapon_grenade_launcher
		M60機關槍 => weapon_rifle_m60
		近戰武器 => weapon_melee
		電鋸 => weapon_chainsaw
		CSS-MP5衝鋒槍 => weapon_smg_mp5
		CSS-SG552步槍 => weapon_rifle_sg552
		CSS-Scout狙擊槍 => weapon_sniper_scout
		CSS-AWP狙擊槍 => weapon_sniper_awp
		汽油彈 => weapon_molotov
		土製炸彈 => weapon_pipe_bomb
		膽汁瓶 => weapon_vomitjar
		電擊器 => weapon_defibrillator
		藥丸 => weapon_pain_pills
		腎上腺素 => weapon_adrenaline
		近戰武器 => weapon_melee
		電鋸 => weapon_chainsaw
		燃燒彈包 => weapon_upgradepack_incendiary
		高爆彈包 => weapon_upgradepack_explosive
		汽油桶 => weapon_gascan
		煙火盒 => weapon_fireworkcrate
		瓦斯罐 => weapon_propanetank
		氧氣罐 => weapon_oxygentan
		```