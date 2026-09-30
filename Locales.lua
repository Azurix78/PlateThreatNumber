local _, addon = ...
local keys = { "DESCRIPTION", "ENABLED", "ROLE", "AUTO", "TANK", "NONTANK", "FONT_SIZE", "OFFSET_X", "OFFSET_Y", "HELP" }
local locales = {
    enUS = {
        "Shows your threat minus the highest threat of another group member or pet, beside enemy nameplates.",
        "Enable", "Role (saved per character)", "Automatic (group role)", "Tank", "DPS / healer",
        "Text size", "Horizontal offset", "Vertical offset",
        "Only appears in combat, when you and another participant have threat on the enemy. Tank: positive green, zero or negative red; other roles: reversed. Automatic mode uses DPS / healer when no role is assigned. Hidden when data is unavailable. /ptn opens these settings.",
    },
    frFR = {
        "Affiche votre menace moins la menace maximale d’un autre membre du groupe ou familier, à côté des barres de nom ennemies.",
        "Activer", "Rôle (enregistré par personnage)", "Automatique (rôle de groupe)", "Tank", "DPS / soigneur",
        "Taille du texte", "Décalage horizontal", "Décalage vertical",
        "Visible uniquement en combat, si vous et un autre participant avez de la menace sur l’ennemi. Tank : positif en vert, nul ou négatif en rouge ; autres rôles : inverse. Sans rôle déclaré, le mode automatique utilise DPS / soigneur. Masqué si les données sont indisponibles. /ptn ouvre ces réglages.",
    },
    deDE = {
        "Zeigt eure Bedrohung abzüglich der höchsten Bedrohung eines anderen Gruppenmitglieds oder Begleiters neben gegnerischen Namensplaketten.",
        "Aktivieren", "Rolle (pro Charakter gespeichert)", "Automatisch (Gruppenrolle)", "Tank", "Schaden / Heilung",
        "Textgröße", "Horizontaler Versatz", "Vertikaler Versatz",
        "Nur im Kampf sichtbar, wenn ihr und ein weiterer Teilnehmer Bedrohung beim Gegner habt. Tank: positiv grün, null oder negativ rot; andere Rollen: umgekehrt. Ohne zugewiesene Rolle gilt automatisch Schaden / Heilung. Bei fehlenden Daten ausgeblendet. /ptn öffnet diese Einstellungen.",
    },
    esES = {
        "Muestra tu amenaza menos la amenaza más alta de otro miembro del grupo o mascota junto a las placas de nombre enemigas.",
        "Activar", "Función (guardada por personaje)", "Automática (función del grupo)", "Tanque", "DPS / sanador",
        "Tamaño del texto", "Desplazamiento horizontal", "Desplazamiento vertical",
        "Solo se muestra en combate si tú y otro participante tenéis amenaza sobre el enemigo. Tanque: positivo en verde, cero o negativo en rojo; otras funciones: al revés. Sin función asignada se usa DPS / sanador. Se oculta si no hay datos disponibles. /ptn abre estos ajustes.",
    },
    esMX = {
        "Muestra tu amenaza menos la amenaza más alta de otro miembro del grupo o mascota junto a las placas de nombre enemigas.",
        "Activar", "Función (guardada por personaje)", "Automática (función del grupo)", "Tanque", "DPS / sanador",
        "Tamaño del texto", "Desplazamiento horizontal", "Desplazamiento vertical",
        "Solo se muestra en combate si tú y otro participante tienen amenaza sobre el enemigo. Tanque: positivo en verde, cero o negativo en rojo; otras funciones: al revés. Sin función asignada se usa DPS / sanador. Se oculta si los datos no están disponibles. /ptn abre esta configuración.",
    },
    itIT = {
        "Mostra la tua minaccia meno la minaccia più alta di un altro membro del gruppo o famiglio accanto alle barre dei nomi nemici.",
        "Attiva", "Ruolo (salvato per personaggio)", "Automatico (ruolo nel gruppo)", "Difensore", "Assaltatore / guaritore",
        "Dimensione del testo", "Spostamento orizzontale", "Spostamento verticale",
        "Visibile solo in combattimento se tu e un altro partecipante avete minaccia sul nemico. Difensore: positivo in verde, zero o negativo in rosso; altri ruoli: colori invertiti. Senza un ruolo assegnato viene usato Assaltatore / guaritore. Nascosto se i dati non sono disponibili. /ptn apre queste impostazioni.",
    },
    ptBR = {
        "Exibe sua ameaça menos a maior ameaça de outro integrante do grupo ou ajudante ao lado das placas de nome inimigas.",
        "Ativar", "Função (salva por personagem)", "Automática (função no grupo)", "Tanque", "DPS / curador",
        "Tamanho do texto", "Deslocamento horizontal", "Deslocamento vertical",
        "Aparece apenas em combate, quando você e outro participante têm ameaça sobre o inimigo. Tanque: positivo em verde, zero ou negativo em vermelho; outras funções: cores invertidas. Sem função atribuída, usa DPS / curador. Oculto quando os dados não estão disponíveis. /ptn abre estas configurações.",
    },
    ruRU = {
        "Показывает вашу угрозу за вычетом наибольшей угрозы другого участника группы или питомца рядом с индикаторами здоровья противников.",
        "Включить", "Роль (сохраняется для персонажа)", "Автоматически (роль в группе)", "Танк", "Боец / лекарь",
        "Размер текста", "Смещение по горизонтали", "Смещение по вертикали",
        "Отображается только в бою, если вы и ещё один участник имеете угрозу у противника. Танк: положительное значение зелёное, ноль или отрицательное — красное; другие роли: наоборот. Без назначенной роли используется Боец / лекарь. Скрывается при недоступных данных. /ptn открывает эти настройки.",
    },
    koKR = {
        "자신의 위협 수준에서 다른 파티원 또는 소환수 중 가장 높은 위협 수준을 뺀 값을 적 이름표 옆에 표시합니다.",
        "사용", "역할 (캐릭터별 저장)", "자동 (파티 역할)", "방어 담당", "공격 / 치유 담당",
        "글자 크기", "가로 위치 조정", "세로 위치 조정",
        "전투 중 자신과 다른 참여자가 해당 적에 대한 위협 수준을 가지고 있을 때만 표시됩니다. 방어 담당: 양수는 녹색, 0 또는 음수는 빨간색이며 다른 역할은 반대입니다. 지정된 역할이 없으면 공격 / 치유 담당으로 처리합니다. 정보를 사용할 수 없으면 숨깁니다. /ptn으로 설정을 엽니다.",
    },
    zhCN = {
        "在敌方姓名板旁显示你的仇恨值减去其他队员或宠物中最高仇恨值的差值。",
        "启用", "职责（按角色保存）", "自动（队伍职责）", "坦克", "输出 / 治疗",
        "文字大小", "水平偏移", "垂直偏移",
        "仅在战斗中，且你和其他参与者对该敌人有仇恨时显示。坦克：正数为绿色，零或负数为红色；其他职责的颜色相反。未分配职责时，自动模式按输出 / 治疗处理。数据不可用时隐藏。输入 /ptn 打开设置。",
    },
    zhTW = {
        "在敵方名條旁顯示你的仇恨值減去其他隊員或寵物中最高仇恨值的差值。",
        "啟用", "角色職責（依角色儲存）", "自動（隊伍職責）", "坦克", "傷害輸出 / 治療",
        "文字大小", "水平位移", "垂直位移",
        "僅在戰鬥中，且你和其他參與者對該敵人有仇恨時顯示。坦克：正數為綠色，零或負數為紅色；其他職責的顏色相反。未分配職責時，自動模式視為傷害輸出 / 治療。資料無法取得時隱藏。輸入 /ptn 開啟設定。",
    },
}
locales.enGB = locales.enUS
local selected = locales[GetLocale()] or locales.enUS
addon.L = {}
for i, key in ipairs(keys) do addon.L[key] = selected[i] or locales.enUS[i] end
-- Prefer the client's terminology for the tank role where available.
if type(_G.TANK) == "string" then addon.L.TANK = _G.TANK end
