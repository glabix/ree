# frozen_string_literal: true

# Точка входа для продуктового кода: прикрепить к текущему аудируемому вызову
# то, что известно только внутри — какое право проверено, к чьим данным и к
# какому объекту обратились.
#
# Почему fn, а не голая константа ReeAudit.annotate: одного `depends_on
# :ree_audit` хватило бы, чтобы пакет загрузился, но проверка объявленной
# зависимости (check_package_dependency_added) срабатывает только для
# `link`/`import`. Голая константа проходит мимо неё — и удаление `depends_on`
# как «неиспользуемого» уронило бы приложение NameError'ом уже в проде.
class ReeAudit::AnnotateAudit
  include Ree::FnDSL

  fn :annotate_audit do
    # fn из общего пакета иначе не подменить в спеках приложения
    freeze false
  end

  doc("Прикрепляет факты приложения к текущему событию аудита. nil — если аудит выключен или вызов пришёл не из аудируемого маршрута.")
  contract(Ksplat[RestKeys => Any] => Nilor[Hash])
  def call(**attrs)
    ReeAudit.annotate(**attrs)
  end
end
