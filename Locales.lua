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
local debugKeys = {
    "DEBUG", "DEBUG_HELP", "DEBUG_ON", "DEBUG_OFF", "DEBUG_STATUS",
    "D_SHOWN", "D_SOLO", "D_NO_RIVAL", "D_SECRET", "D_ERROR", "D_INVALID",
    "D_NO_THREAT", "D_FILTERED", "D_FRAME", "D_POSITION", "D_WAITING",
}
local debugLocales = {
    enUS = {
        "Debug / solo test",
        "Debug allows your own threat to appear in solo combat without a rival, marked with *. /ptn debug toggles it; /ptn status reports the last display or blocking reason for each plate. Restricted data stays hidden.",
        "Debug enabled. Fight an enemy solo, then use /ptn status. * means your own threat without a rival.",
        "Debug disabled.",
        "v%s | enabled=%s, combat=%s, debug=%s | visible=%d, tracked=%d, threat events=%d, refreshes=%d",
        "Threat difference displayed", "Solo test: own threat displayed (*)", "No rival with positive threat",
        "Data restricted by the client", "API call failed", "Data missing or invalid",
        "No player threat entry", "Unit excluded by combat filters", "Nameplate frame unavailable or not ready",
        "Health bar unavailable or hidden", "No calculation recorded yet: enable debug and enter combat. Results remain available after combat until debug is turned off or the UI is reloaded.",
    },
    frFR = {
        "Debug / test en solo",
        "Le debug affiche votre propre menace en combat solo sans concurrent, avec un *. /ptn debug l’active ou le désactive ; /ptn status indique le dernier affichage ou blocage de chaque plaque. Les données protégées restent masquées.",
        "Debug activé. Combattez un ennemi en solo, puis utilisez /ptn status. * indique votre propre menace sans concurrent.",
        "Debug désactivé.",
        "v%s | actif=%s, combat=%s, debug=%s | visibles=%d, suivies=%d, événements de menace=%d, actualisations=%d",
        "Écart de menace affiché", "Test solo : menace personnelle affichée (*)", "Aucun concurrent avec une menace positive",
        "Données protégées par le client", "Échec de l’appel API", "Données absentes ou invalides",
        "Joueur absent de la table de menace", "Unité exclue par les filtres de combat", "Cadre de la plaque indisponible ou pas encore prêt",
        "Barre de vie indisponible ou masquée", "Aucun calcul enregistré : activez le debug et entrez en combat. Les résultats restent disponibles après le combat jusqu’à la désactivation du debug ou au rechargement de l’interface.",
    },
    deDE = {
        "Debug / Solotest",
        "Im Debugmodus wird im Solokampf ohne Konkurrenten eure eigene Bedrohung mit * angezeigt. /ptn debug schaltet den Modus um; /ptn status zeigt das letzte Ergebnis oder den Grund für die fehlende Anzeige pro Namensplakette. Geschützte Daten bleiben verborgen.",
        "Debug aktiviert. Kämpft solo gegen einen Gegner und verwendet dann /ptn status. * kennzeichnet eure eigene Bedrohung ohne Konkurrenten.",
        "Debug deaktiviert.",
        "v%s | aktiv=%s, Kampf=%s, Debug=%s | sichtbar=%d, erfasst=%d, Bedrohungsereignisse=%d, Aktualisierungen=%d",
        "Bedrohungsdifferenz angezeigt", "Solotest: eigene Bedrohung angezeigt (*)", "Kein Konkurrent mit positiver Bedrohung",
        "Daten vom Client geschützt", "API-Aufruf fehlgeschlagen", "Daten fehlen oder sind ungültig",
        "Kein Bedrohungseintrag für den Spieler", "Einheit durch Kampffilter ausgeschlossen", "Namensplakettenrahmen nicht verfügbar oder noch nicht bereit",
        "Gesundheitsbalken nicht verfügbar oder verborgen", "Noch keine Berechnung: Aktiviert Debug und beginnt einen Kampf. Ergebnisse bleiben nach dem Kampf bis zum Abschalten von Debug oder Neuladen der Benutzeroberfläche verfügbar.",
    },
    esES = {
        "Depuración / prueba en solitario",
        "La depuración muestra tu amenaza en combate en solitario sin rivales, marcada con *. /ptn debug activa o desactiva el modo; /ptn status muestra el último resultado o motivo de ocultación de cada placa. Los datos protegidos permanecen ocultos.",
        "Depuración activada. Combate contra un enemigo en solitario y usa /ptn status. * indica tu amenaza sin rivales.",
        "Depuración desactivada.",
        "v%s | activo=%s, combate=%s, depuración=%s | visibles=%d, registradas=%d, eventos de amenaza=%d, actualizaciones=%d",
        "Diferencia de amenaza mostrada", "Prueba en solitario: amenaza propia mostrada (*)", "Ningún rival con amenaza positiva",
        "Datos restringidos por el cliente", "Error en la llamada a la API", "Datos ausentes o no válidos",
        "El jugador no figura en la tabla de amenaza", "Unidad excluida por los filtros de combate", "Marco de la placa no disponible o aún no preparado",
        "Barra de salud no disponible u oculta", "Aún no hay cálculos: activa la depuración y entra en combate. Los resultados se conservan hasta desactivar la depuración o recargar la interfaz.",
    },
    esMX = {
        "Depuración / prueba en solitario",
        "La depuración muestra tu amenaza en combate en solitario sin rivales, marcada con *. /ptn debug activa o desactiva el modo; /ptn status muestra el último resultado o motivo de ocultación de cada placa. Los datos protegidos permanecen ocultos.",
        "Depuración activada. Combate contra un enemigo en solitario y usa /ptn status. * indica tu amenaza sin rivales.",
        "Depuración desactivada.",
        "v%s | activo=%s, combate=%s, depuración=%s | visibles=%d, registradas=%d, eventos de amenaza=%d, actualizaciones=%d",
        "Diferencia de amenaza mostrada", "Prueba en solitario: amenaza propia mostrada (*)", "Ningún rival con amenaza positiva",
        "Datos restringidos por el cliente", "Error en la llamada a la API", "Datos ausentes o no válidos",
        "El jugador no figura en la tabla de amenaza", "Unidad excluida por los filtros de combate", "Marco de la placa no disponible o aún no preparado",
        "Barra de salud no disponible u oculta", "Aún no hay cálculos: activa la depuración y entra en combate. Los resultados se conservan hasta desactivar la depuración o recargar la interfaz.",
    },
    itIT = {
        "Debug / prova in solitaria",
        "Il debug mostra la tua minaccia in combattimento in solitaria senza rivali, contrassegnata da *. /ptn debug attiva o disattiva la modalità; /ptn status mostra l’ultimo risultato o motivo di mancata visualizzazione per ogni barra. I dati protetti restano nascosti.",
        "Debug attivato. Combatti un nemico in solitaria, poi usa /ptn status. * indica la tua minaccia senza rivali.",
        "Debug disattivato.",
        "v%s | attivo=%s, combattimento=%s, debug=%s | visibili=%d, seguite=%d, eventi di minaccia=%d, aggiornamenti=%d",
        "Differenza di minaccia visualizzata", "Prova in solitaria: minaccia personale visualizzata (*)", "Nessun rivale con minaccia positiva",
        "Dati protetti dal client", "Chiamata API non riuscita", "Dati mancanti o non validi",
        "Giocatore assente dalla tabella di minaccia", "Unità esclusa dai filtri di combattimento", "Riquadro della barra non disponibile o non ancora pronto",
        "Barra della salute non disponibile o nascosta", "Nessun calcolo registrato: attiva il debug ed entra in combattimento. I risultati restano disponibili fino alla disattivazione del debug o al ricaricamento dell’interfaccia.",
    },
    ptBR = {
        "Depuração / teste solo",
        "A depuração exibe sua ameaça em combate solo sem rivais, marcada com *. /ptn debug ativa ou desativa o modo; /ptn status mostra o último resultado ou motivo de ocultação de cada placa. Dados protegidos continuam ocultos.",
        "Depuração ativada. Enfrente um inimigo solo e use /ptn status. * indica sua ameaça sem rivais.",
        "Depuração desativada.",
        "v%s | ativo=%s, combate=%s, depuração=%s | visíveis=%d, acompanhadas=%d, eventos de ameaça=%d, atualizações=%d",
        "Diferença de ameaça exibida", "Teste solo: ameaça própria exibida (*)", "Nenhum rival com ameaça positiva",
        "Dados protegidos pelo cliente", "Falha na chamada da API", "Dados ausentes ou inválidos",
        "Jogador ausente da tabela de ameaça", "Unidade excluída pelos filtros de combate", "Quadro da placa indisponível ou ainda não pronto",
        "Barra de vida indisponível ou oculta", "Nenhum cálculo registrado: ative a depuração e entre em combate. Os resultados permanecem disponíveis até desativar a depuração ou recarregar a interface.",
    },
    ruRU = {
        "Отладка / одиночный тест",
        "Отладка показывает вашу угрозу в одиночном бою без соперников со знаком *. /ptn debug переключает режим; /ptn status выводит последний результат или причину отсутствия числа для каждого индикатора. Защищённые данные остаются скрытыми.",
        "Отладка включена. Вступите в одиночный бой и используйте /ptn status. * обозначает вашу угрозу без соперников.",
        "Отладка выключена.",
        "v%s | включено=%s, бой=%s, отладка=%s | видимых=%d, отслеживаемых=%d, событий угрозы=%d, обновлений=%d",
        "Разница угрозы показана", "Одиночный тест: показана собственная угроза (*)", "Нет соперника с положительной угрозой",
        "Данные защищены клиентом", "Ошибка вызова API", "Данные отсутствуют или некорректны",
        "Игрок отсутствует в таблице угрозы", "Объект исключён фильтрами боя", "Рамка индикатора недоступна или ещё не готова",
        "Полоса здоровья недоступна или скрыта", "Расчётов пока нет: включите отладку и вступите в бой. Результаты доступны до выключения отладки или перезагрузки интерфейса.",
    },
    koKR = {
        "디버그 / 솔로 테스트",
        "디버그 모드에서는 경쟁자가 없는 솔로 전투에서도 자신의 위협 수준을 * 표시와 함께 보여줍니다. /ptn debug로 전환하고 /ptn status로 각 이름표의 마지막 표시 결과나 숨김 이유를 확인하세요. 보호된 정보는 계속 숨겨집니다.",
        "디버그가 켜졌습니다. 혼자 적과 싸운 후 /ptn status를 입력하세요. *는 경쟁자가 없는 자신의 위협 수준을 뜻합니다.",
        "디버그가 꺼졌습니다.",
        "v%s | 활성=%s, 전투=%s, 디버그=%s | 표시=%d, 추적=%d, 위협 이벤트=%d, 갱신=%d",
        "위협 수준 차이 표시됨", "솔로 테스트: 자신의 위협 수준 표시됨 (*)", "위협 수준이 양수인 경쟁자 없음",
        "클라이언트가 보호하는 정보", "API 호출 실패", "정보가 없거나 유효하지 않음",
        "플레이어가 위협 목록에 없음", "전투 필터로 제외된 대상", "이름표 프레임을 사용할 수 없거나 아직 준비되지 않음",
        "생명력 바를 사용할 수 없거나 숨겨짐", "아직 계산 기록이 없습니다. 디버그를 켜고 전투를 시작하세요. 디버그를 끄거나 인터페이스를 다시 불러올 때까지 결과가 유지됩니다.",
    },
    zhCN = {
        "调试 / 单人测试",
        "调试模式会在没有竞争者的单人战斗中显示你自己的仇恨值，并标注 *。用 /ptn debug 切换模式，/ptn status 查看各姓名板上次的显示结果或隐藏原因。受保护的数据仍然隐藏。",
        "调试已启用。单人攻击一个敌人，然后输入 /ptn status。* 表示没有竞争者时你自己的仇恨值。",
        "调试已禁用。",
        "v%s | 启用=%s，战斗=%s，调试=%s | 可见=%d，跟踪=%d，仇恨事件=%d，刷新=%d",
        "已显示仇恨差值", "单人测试：已显示自身仇恨 (*)", "没有仇恨值为正的竞争者",
        "数据受客户端保护", "API 调用失败", "数据缺失或无效",
        "玩家不在仇恨列表中", "单位被战斗筛选条件排除", "姓名板框体不可用或尚未就绪",
        "生命条不可用或已隐藏", "尚无计算记录：请启用调试并进入战斗。结果会保留到关闭调试或重新加载界面为止。",
    },
    zhTW = {
        "除錯 / 單人測試",
        "除錯模式會在沒有競爭者的單人戰鬥中顯示你自己的仇恨值，並標註 *。用 /ptn debug 切換模式，/ptn status 查看各名條上次的顯示結果或隱藏原因。受保護的資料仍然隱藏。",
        "除錯已啟用。單人攻擊一個敵人，然後輸入 /ptn status。* 表示沒有競爭者時你自己的仇恨值。",
        "除錯已停用。",
        "v%s | 啟用=%s，戰鬥=%s，除錯=%s | 可見=%d，追蹤=%d，仇恨事件=%d，更新=%d",
        "已顯示仇恨差值", "單人測試：已顯示自身仇恨 (*)", "沒有仇恨值為正的競爭者",
        "資料受用戶端保護", "API 呼叫失敗", "資料缺失或無效",
        "玩家不在仇恨列表中", "單位被戰鬥篩選條件排除", "名條框架無法使用或尚未就緒",
        "生命條無法使用或已隱藏", "尚無計算紀錄：請啟用除錯並進入戰鬥。結果會保留到關閉除錯或重新載入介面為止。",
    },
}
local baseCount = #keys
debugKeys[#debugKeys + 1] = "DEBUG_LAST"
local lastLabels = {
    enUS = "Previous combat result", frFR = "Résultat précédent en combat",
    deDE = "Vorheriges Kampfergebnis", esES = "Resultado anterior en combate",
    esMX = "Resultado anterior en combate", itIT = "Risultato precedente in combattimento",
    ptBR = "Resultado anterior em combate", ruRU = "Предыдущий результат в бою",
    koKR = "이전 전투 결과", zhCN = "此前战斗结果", zhTW = "先前戰鬥結果",
}
for code, values in pairs(debugLocales) do values[#debugKeys] = lastLabels[code] end
for _, key in ipairs(debugKeys) do keys[#keys + 1] = key end
for code, values in pairs(locales) do
    for i in ipairs(debugKeys) do values[baseCount + i] = debugLocales[code][i] end
end
locales.enGB = locales.enUS
local selected = locales[GetLocale()] or locales.enUS
addon.L = {}
for i, key in ipairs(keys) do addon.L[key] = selected[i] or locales.enUS[i] end
-- Prefer the client's terminology for the tank role where available.
if type(_G.TANK) == "string" then addon.L.TANK = _G.TANK end
