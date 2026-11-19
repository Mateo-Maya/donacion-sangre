*** Settings ***
Documentation     Pruebas automatizadas de la pantalla de Registro de DonaVida (/registro).
...               Verifican la historia de usuario HU-D01 "Registro en la plataforma":
...               cada caso de prueba corresponde a un criterio de aceptación (CA).
...
...               REQUISITOS (instalar una sola vez):
...                 pip install robotframework robotframework-seleniumlibrary
...               Se necesita Google Chrome (Selenium Manager descarga el chromedriver
...               automáticamente en Selenium 4.6 o superior).
...
...               AMBIENTE: la aplicación debe estar corriendo en local.
...                 Backend:  http://localhost:8081   (cd backend  y  mvnw spring-boot:run)
...                 Frontend: http://localhost:5173   (cd frontend y  npm run dev)
...
...               EJECUCIÓN (desde esta carpeta):
...                 robot -d resultados registro_donante.robot
...
...               Al terminar se generan report.html, log.html y output.xml en "resultados".
...               NOTA: el registro exitoso crea un usuario real en la base de datos;
...               por eso usa un correo y un documento únicos en cada ejecución.
Library           SeleniumLibrary
Test Tags         HU-D01    registro
Test Setup        Abrir Formulario De Registro
Test Teardown     Close Browser
Suite Teardown    Close All Browsers    # Cierra el navegador al terminar, pase o falle la prueba

*** Variables ***
${URL}                    http://localhost:5173/registro
${NAVEGADOR}              chrome
${TIMEOUT}                10s

# --- Datos de prueba ---
${CONTRASENA_VALIDA}      Donante123*
${CORREO_EXISTENTE}       admin@donavida.com     # Usuario que ya existe en la base de datos
${NOMBRE}                 Robot
${APELLIDO}               Prueba
${CELULAR_VALIDO}         3001234567
${FECHA_VALIDA}           1995-05-10             # Formato ISO: año-mes-día
${TIPO_SANGRE}            O+
${PESO_VALIDO}            70
${LATITUD}                6.2442                 # Ubicación simulada: Medellín
${LONGITUD}               -75.5812

# --- Paso 1: Cuenta ---
${CAMPO_CORREO}           xpath=//input[@placeholder='tucorreo@ejemplo.com']
${CAMPO_CONTRASENA}       xpath=//input[@placeholder='Crea una contraseña segura']
${CAMPO_CONFIRMAR}        xpath=//input[@placeholder='Repite tu contraseña']
${BOTON_CONTINUAR}        xpath=//button[contains(normalize-space(),'CONTINUAR')]

# --- Paso 2: Perfil ---
${CAMPO_DOCUMENTO}        xpath=//input[@placeholder='1234567890']
${CAMPO_NOMBRE}           xpath=//input[@placeholder='Carlos']
${CAMPO_APELLIDO}         xpath=//input[@placeholder='Díaz']
${CAMPO_CELULAR}          xpath=//input[@placeholder='3001234567']
${CAMPO_FECHA}            css=input[type='date']
${LISTA_GENERO}           xpath=//select[option[@value='MASCULINO']]

# --- Paso 3: Donante ---
${CAMPO_PESO}             xpath=//input[@placeholder='70']
${CAMPO_CIUDAD}           xpath=//input[@placeholder='Medellín']
${CAMPO_DEPARTAMENTO}     xpath=//input[@placeholder='Antioquia']
${BOTON_UBICACION}        xpath=//button[.//p[text()='Detectar mi ubicación']]
${UBICACION_DETECTADA}    xpath=//p[text()='Ubicación detectada']
${BOTON_CREAR_CUENTA}     xpath=//button[contains(normalize-space(),'CREAR MI CUENTA')]

# --- Mensajes ---
${ALERTA_ERROR}           xpath=//div[contains(@class,'animate-shake')]    # Recuadro rojo de error general

*** Test Cases ***
CA1 y CA4 - Registro exitoso crea el donante y lo redirige a su home
    [Documentation]    Con todos los campos válidos el sistema crea el usuario con rol DONANTE,
    ...                lo deja autenticado (CA1) y lo redirige al home del donante (CA4).
    [Tags]             CA1    CA4    positivo    smoke
    ${correo}    ${documento}=    Generar Datos Unicos
    Completar Paso Cuenta     ${correo}    ${CONTRASENA_VALIDA}
    Completar Paso Perfil     ${documento}
    Completar Paso Donante    ${PESO_VALIDO}
    Crear La Cuenta
    Validar Que Quedo Autenticado En El Home Del Donante

CA2 - Correo ya registrado muestra mensaje y no crea el usuario
    [Documentation]    Si el correo ya existe, el sistema muestra "El correo ya está registrado"
    ...                y el visitante sigue en el registro sin sesión iniciada.
    [Tags]             CA2    negativo
    ${correo}    ${documento}=    Generar Datos Unicos
    Completar Paso Cuenta     ${CORREO_EXISTENTE}    ${CONTRASENA_VALIDA}
    Completar Paso Perfil     ${documento}
    Completar Paso Donante    ${PESO_VALIDO}
    Crear La Cuenta
    Validar Que El Registro Fue Rechazado    El correo ya está registrado

CA3 - Peso menor a 50 kg muestra mensaje y bloquea el registro
    [Documentation]    Con un peso de 45 kg el sistema muestra "El peso mínimo para donar es 50 kg"
    ...                y no permite pulsar CREAR MI CUENTA.
    [Tags]             CA3    negativo
    ${correo}    ${documento}=    Generar Datos Unicos
    Completar Paso Cuenta     ${correo}    ${CONTRASENA_VALIDA}
    Completar Paso Perfil     ${documento}
    Completar Paso Donante    45
    Wait Until Page Contains          El peso mínimo para donar es 50 kg
    Element Should Be Disabled        ${BOTON_CREAR_CUENTA}
    Capture Page Screenshot           ca3_peso_minimo.png

Contraseña débil marca en rojo los requisitos que faltan
    [Documentation]    Validación adicional del paso 1: con "abcdefgh" faltan mayúscula, número
    ...                y carácter especial; esos requisitos se marcan en rojo con ✗ y no se puede continuar.
    [Tags]             adicional    negativo
    Input Text        ${CAMPO_CORREO}         robot@prueba.com
    Input Password    ${CAMPO_CONTRASENA}     abcdefgh
    Requisito De Contraseña Debe Estar En Rojo    Una mayúscula
    Requisito De Contraseña Debe Estar En Rojo    Un número
    Requisito De Contraseña Debe Estar En Rojo    Un especial
    Element Should Be Disabled    ${BOTON_CONTINUAR}
    Capture Page Screenshot       contrasena_debil.png

Datos inválidos del perfil muestran el motivo y bloquean el avance
    [Documentation]    Validaciones adicionales del paso 2 (prueba guiada por datos con [Template]):
    ...                cada fila llena el perfil con un dato inválido y verifica el mensaje mostrado.
    [Tags]             adicional    negativo
    [Template]         Perfil Con Dato Invalido Debe Mostrar Mensaje
    # documento     celular        fecha          mensaje esperado
    123             3001234567     1995-05-10     Mínimo 5 dígitos
    1234567890      2001234567     1995-05-10     El celular debe empezar por 3
    1234567890      30012          1995-05-10     Debe tener 10 dígitos
    1234567890      3001234567     2012-01-01     fecha de nacimiento (entre 18 y 65 años)

*** Keywords ***
Abrir Formulario De Registro
    [Documentation]    Abre el navegador en /registro, simula la ubicación y espera el formulario.
    Open Browser    ${URL}    ${NAVEGADOR}
    Maximize Browser Window
    Set Selenium Timeout    ${TIMEOUT}
    Simular Ubicacion Del Navegador
    Wait Until Element Is Visible    ${CAMPO_CORREO}

Simular Ubicacion Del Navegador
    [Documentation]    El paso 3 exige "Detectar mi ubicación" (GPS del navegador). En una prueba
    ...                automatizada no hay GPS ni alguien que acepte el permiso, así que se usa el
    ...                protocolo DevTools de Chrome para conceder el permiso y fijar la ubicación.
    ${sl}=        Get Library Instance    SeleniumLibrary
    ${driver}=    Set Variable    ${sl.driver}
    Evaluate    $driver.execute_cdp_cmd('Browser.grantPermissions', {'permissions': ['geolocation']})
    Evaluate    $driver.execute_cdp_cmd('Emulation.setGeolocationOverride', {'latitude': float($LATITUD), 'longitude': float($LONGITUD), 'accuracy': 100})

Generar Datos Unicos
    [Documentation]    Devuelve un correo y un número de documento que no existen en la base de
    ...                datos, usando la hora actual (segundos desde 1970) como marca única.
    ${marca}=    Get Time    epoch
    RETURN    robot.${marca}@prueba.com    ${marca}

Completar Paso Cuenta
    [Documentation]    Paso 1: correo, contraseña y confirmación; luego CONTINUAR.
    [Arguments]    ${correo}    ${contrasena}
    Input Text        ${CAMPO_CORREO}        ${correo}
    Input Password    ${CAMPO_CONTRASENA}    ${contrasena}
    Input Password    ${CAMPO_CONFIRMAR}     ${contrasena}
    Click Button      ${BOTON_CONTINUAR}
    Wait Until Element Is Visible    ${CAMPO_DOCUMENTO}

Completar Paso Perfil
    [Documentation]    Paso 2: datos personales válidos; luego CONTINUAR.
    [Arguments]    ${documento}
    Llenar Datos Del Perfil    ${documento}    ${CELULAR_VALIDO}    ${FECHA_VALIDA}
    Click Button    ${BOTON_CONTINUAR}
    Wait Until Element Is Visible    ${CAMPO_PESO}

Llenar Datos Del Perfil
    [Documentation]    Llena todos los campos del paso 2 con los valores recibidos.
    [Arguments]    ${documento}    ${celular}    ${fecha}
    Input Text    ${CAMPO_DOCUMENTO}    ${documento}
    Input Text    ${CAMPO_NOMBRE}       ${NOMBRE}
    Input Text    ${CAMPO_APELLIDO}     ${APELLIDO}
    Input Text    ${CAMPO_CELULAR}      ${celular}
    Escribir Fecha De Nacimiento    ${fecha}
    Select From List By Value    ${LISTA_GENERO}    OTRO

Escribir Fecha De Nacimiento
    [Documentation]    El campo es un <input type="date">: lo que se teclea depende del idioma del
    ...                sistema (dd/mm/aaaa o mm/dd/aaaa). Para que la prueba funcione en cualquier
    ...                equipo se asigna la fecha ISO con JavaScript y se dispara el evento "input"
    ...                para que React registre el cambio.
    [Arguments]    ${fecha}
    Execute Javascript
    ...    const campo = document.querySelector("input[type='date']");
    ...    const asignar = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
    ...    asignar.call(campo, arguments[0]);
    ...    campo.dispatchEvent(new Event('input', { bubbles: true }));
    ...    ARGUMENTS    ${fecha}

Completar Paso Donante
    [Documentation]    Paso 3: tipo de sangre, peso, ciudad, departamento y ubicación.
    [Arguments]    ${peso}
    Click Button    xpath=//button[normalize-space()='${TIPO_SANGRE}']
    Input Text      ${CAMPO_PESO}            ${peso}
    Input Text      ${CAMPO_CIUDAD}          Medellín
    Input Text      ${CAMPO_DEPARTAMENTO}    Antioquia
    Click Button    ${BOTON_UBICACION}
    Wait Until Element Is Visible    ${UBICACION_DETECTADA}

Crear La Cuenta
    [Documentation]    Pulsa CREAR MI CUENTA (debe estar habilitado).
    Element Should Be Enabled    ${BOTON_CREAR_CUENTA}
    Click Button    ${BOTON_CREAR_CUENTA}

Validar Que Quedo Autenticado En El Home Del Donante
    [Documentation]    Verifica la redirección a /home-donante, el saludo con el nombre y que
    ...                el token de sesión quedó guardado en el navegador.
    Wait Until Location Contains    /home-donante
    Wait Until Page Contains        Hola, ${NOMBRE}
    ${token}=    Execute Javascript    return window.localStorage.getItem('token');
    Should Not Be Equal    ${token}    ${None}    msg=No quedó un token de sesión guardado.
    Capture Page Screenshot    ca1_ca4_registro_exitoso.png

Validar Que El Registro Fue Rechazado
    [Documentation]    Verifica el mensaje de error, que se sigue en /registro y que no hay sesión.
    [Arguments]    ${mensaje}
    Wait Until Element Contains    ${ALERTA_ERROR}    ${mensaje}
    Location Should Contain    /registro
    ${token}=    Execute Javascript    return window.localStorage.getItem('token');
    Should Be Equal    ${token}    ${None}    msg=Se inició sesión aunque el registro debía fallar.
    Capture Page Screenshot    ca2_correo_registrado.png

Requisito De Contraseña Debe Estar En Rojo
    [Documentation]    Verifica que el requisito aparece con ✗ y en color rojo (#ff4d6d).
    ...                La lista aparece con una animación, por eso se espera a que sea visible.
    [Arguments]    ${requisito}
    ${locator}=    Set Variable    xpath=//div[contains(@class,'ff4d6d') and contains(normalize-space(),'${requisito}')]
    Wait Until Element Is Visible    ${locator}
    Element Should Contain       ${locator}    ✗

Perfil Con Dato Invalido Debe Mostrar Mensaje
    [Documentation]    Plantilla: reinicia el formulario, completa el paso 1, llena el perfil con
    ...                los valores recibidos y verifica el mensaje y que CONTINUAR siga bloqueado.
    [Arguments]    ${documento}    ${celular}    ${fecha}    ${mensaje}
    Go To    ${URL}
    Completar Paso Cuenta      robot@prueba.com    ${CONTRASENA_VALIDA}
    Llenar Datos Del Perfil    ${documento}    ${celular}    ${fecha}
    Wait Until Page Contains      ${mensaje}
    Element Should Be Disabled    ${BOTON_CONTINUAR}
    Capture Page Screenshot    perfil_invalido_{index}.png
