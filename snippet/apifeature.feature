#language: ru

# Youtrack:
#  - 
# Swagger:
#  - 
# Run:
#  - make testing-codecept-api-path path=v3/public/.feature

Функционал: 

  Предыстория:
    Пусть в каталоге есть следующие заведения:
      | id | name     | slug      | active |
      | 10 | Баранчик | barancheg | true   |

  Сценарий: RCN. api.
    Дано я делаю GET запрос "/api/public/v3/places/1/reviews" с параметрами {"page": 1, "topUser": false, "sort": "created", "withPhoto": false}
    Тогда код ответа api должен быть "200"
    И поле ответа "[data][placeReviews][0][text]" должно быть "Отзыв о ресторане <p></p>"
