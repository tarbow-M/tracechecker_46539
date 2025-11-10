## Usersテーブル

| Column             | Type   | Options     |
| ------------------ | ------ | ----------- |
| personal_num       | string | null: false |
| name               | string | null: false |
| email              | string | null: false, unique:true |
| encrypted_password | string | null: false |

### Association
- has_many :parent_projects
- has_many :templates
- has_many :logs


## Templatesテーブル

| Column  | Type       | Options     |
| ------- | ---------- | ---------------------------- |
| name    | string     | null: false                  |
| range   | jsonb      |
| user    | references | null: false, foreign_key: true |

### Association
- belongs_to :user


## Logsテーブル

| Column      | Type       | Options     |
| ----------- | ---------- | ----------- |
| action_type | string     | null: false            |
| description | text       |
| user        | references | null: false, foreign_key: true |
| project     | references | foreign_key: true |

### Association
- belongs_to :user
- belongs_to :project, optional: true


## ParentProjects テーブル

| Column  | Type       | Options     |
| ------- | ---------- | ----------- |
| name    | string     | null: false |
| user    | references | null: false, foreign_key: true |

### Association
- has_many :projects
- has_many_attached :files (ActiveStorage)
- belongs_to :user


## Projectsテーブル（Child Project）

| Column         | Type       | Options     |
| -------------- | ---------- | ----------- |
| name           | string     | null: false |
| status         | string     |
| is_locked      | boolean    | default: false   |
| last_run       | datetime   |
| diff_count     | integer    |
| parent_project | references | null: false, foreign_key: true |

### Association
- belongs_to :parent_project
- has_many :archived_results, foreign_key: :child_project_id
- has_many :logs


## ArchivedResultsテーブル

| Column        | Type       | Options     |
| ------------- | ---------- | ----------- |
| name          | string     | null: false |
| diff_count    | integer    |
| file_a        | references | foreign_key: (ActiveStorageのID想定) |
| file_b        | references | foreign_key: (ActiveStorageのID想定) |
| child_project | references | null: false, foreign_key: { to_table: :projects } |

### Association
- has_many :trace_results
- belongs_to :child_project, class_name: 'Project'


## TraceResultsテーブル

| Column          | Type       | Options     |
| --------------- | ---------- | ----------- |
| key             | string     | null: false |
| flag            | string     | null: false |
| comment         | text       |
| target_cell     | jsonb      |
| archived_result | references | null: false, foreign_key: true |

### Association
- belongs_to :archived_result

