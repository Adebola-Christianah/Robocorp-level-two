*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.Excel.Files
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Outlook.Application


*** Variables ***
${receipt_directory}=           ${OUTPUT_DIR}${/}receipts${/}
${image_directory}=             ${OUTPUT_DIR}${/}images${/}
${zip_directory}=               ${OUTPUT_DIR}${/}
${Final_receipt_directory}=     ${OUTPUT_DIR}${/}order_receipt${/}


*** Tasks ***
Download CSV
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Login to intranet website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Loop through the csv file to get corresponding data to fill the form
    ${tables}=    Read table from CSV    orders.csv
    FOR    ${table}    IN    @{tables}
        Wait Until Element Is Visible    class:alert-buttons
        Click Button    I guess so...
        Fill and submit the form for one person    ${table}
    END

Close the browser and logout
    Close Browser

Create ZIP package from PDF files
    Archive Folder With Zip    ${receipt_directory}    ${OUTPUT_DIR}${/}order_receipt.zip


*** Keywords ***
Download CSV

Loop through the csv file to get corresponding data to fill the form

Login to intranet website

Fill and submit the form for one person
    [Arguments]    ${table}
    Wait Until Page Contains Element    class:form-group
    Select From List By Value    head    ${table}[Head]
    Select Radio Button    body    ${table}[Body]
    Input Text    //*[@id="root"]/div/div[1]/div/div[1]/form/div[3]/input    ${table}[Legs]
    Input Text    address    ${table}[Address]
    Click Button    Preview

    Set Local Variable    ${image_filename}    ${image_directory}${table}[Order number].png

    Set Local Variable    ${receipt_filename}    ${receipt_directory}${table}[Order number].pdf
    Take a screenshot of the robot    ${table}[Order number]
    Click Button    Order
    ${CHECK}=    Is Element Visible    id:receipt
    WHILE    ${CHECK}==$False
        Click Button    Order

        ${CHECK}=    Is Element Visible    id:receipt
    END
    Store the receipt as pdf    ${table}[Order number]
    Embedded pdf and screenshot
    ...    ${receipt_filename}
    ...    ${image_filename}
    ...    ${table}[Order number]
    # TRY
    #    Click Button    Order
    #    Store the receipt as pdf    ${table}[Order number]
    #    Embedded pdf and screenshot
    #    ...    ${receipt_filename}
    #    ...    ${image_filename}
    #    ...    ${table}[Order number]
    # EXCEPT
    #    Click Button    Order
    #    Wait Until Element Is Visible    id:receipt
    # END

    Click Button    Order another robot

Store the receipt as pdf
    [Arguments]    ${table}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    ${receipt_html}    ${receipt_directory}${table}.pdf

Take a screenshot of the robot
    [Arguments]    ${table}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${image_directory}${table}.png

Embedded pdf and screenshot
    [Arguments]    ${receipt_filename}    ${image_filename}    ${table}
    Open PDF    ${receipt_filename}
    @{pseudo_file_list}=    Create List
    ...    ${receipt_filename}
    ...    ${image_filename}:align=center

    Add Files To PDF    ${pseudo_file_list}    ${receipt_directory}${table}.pdf
    Close Pdf    ${receipt_filename}

Create ZIP package from PDF files

Close the browser and logout
