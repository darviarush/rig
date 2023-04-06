#language: ru

# Youtrack:
#  - 
# Run:
#  - make testing-codecept-sf-path path=fixtures/.feature

Функционал: 

  Предыстория:
    Пусть в каталоге есть следующие заведения:
      | id | name     | slug      | active |
      | 10 | Баранчик | barancheg | true   |

  Сценарий: 1
    Дано название сценария: "Страница заведения"
    Пусть я на странице "/site/all/main/10/"
    Тогда адрес должен соответствовать "/spb/place/barancheg"
    И код ответа сервера должен быть 200
