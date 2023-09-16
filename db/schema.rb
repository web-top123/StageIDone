# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20211228065306) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.string   "full_name"
    t.string   "email_address"
    t.datetime "last_login_at"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "alternate_emails", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "email_address",     null: false
    t.string   "verification_code"
    t.datetime "verified_at"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "alternate_emails", ["email_address"], name: "index_alternate_emails_on_email_address", unique: true, using: :btree
  add_index "alternate_emails", ["user_id"], name: "index_alternate_emails_on_user_id", using: :btree
  add_index "alternate_emails", ["verification_code"], name: "index_alternate_emails_on_verification_code", unique: true, using: :btree

  create_table "app_settings", force: :cascade do |t|
    t.string   "tiny_monthly_plan_id"
    t.string   "tiny_yearly_plan_id"
    t.string   "small_monthly_plan_id"
    t.string   "small_yearly_plan_id"
    t.string   "medium_monthly_plan_id"
    t.string   "medium_yearly_plan_id"
    t.string   "large_monthly_plan_id"
    t.string   "large_yearly_plan_id"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.integer  "tiny_monthly_plan_price_in_cents",    default: 0
    t.integer  "tiny_yearly_plan_price_in_cents",     default: 0
    t.integer  "small_monthly_plan_price_in_cents",   default: 1250
    t.integer  "small_yearly_plan_price_in_cents",    default: 900
    t.integer  "medium_monthly_plan_price_in_cents",  default: 2500
    t.integer  "medium_yearly_plan_price_in_cents",   default: 2200
    t.integer  "large_monthly_plan_price_in_cents",   default: 4000
    t.integer  "large_yearly_plan_price_in_cents",    default: 3500
    t.string   "invoice_monthly_plan_id"
    t.string   "invoice_yearly_plan_id"
    t.integer  "invoice_monthly_plan_price_in_cents", default: 0
    t.integer  "invoice_yearly_plan_price_in_cents",  default: 0
    t.string   "basic_monthly_plan_id"
    t.string   "basic_yearly_plan_id"
    t.integer  "basic_monthly_plan_price_in_cents",   default: 500
    t.integer  "basic_yearly_plan_price_in_cents",    default: 400
  end

  create_table "archived_notifications", force: :cascade do |t|
    t.string   "for_notificable",             null: false
    t.integer  "count",           default: 0, null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "entry_id",                    null: false
    t.integer  "user_id",                     null: false
  end

  add_index "archived_notifications", ["for_notificable", "entry_id", "user_id"], name: "archived_notifications_uniq", unique: true, using: :btree

  create_table "authentications", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.string   "provider",   null: false
    t.string   "uid",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "authentications", ["provider", "uid"], name: "index_authentications_on_provider_and_uid", using: :btree

  create_table "deleted_users", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "email_address"
    t.text     "full_name"
    t.datetime "user_created_at"
    t.integer  "cc_entry",        default: 0
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "entries", force: :cascade do |t|
    t.text     "body"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.integer  "user_id"
    t.date     "occurred_on"
    t.integer  "team_id"
    t.string   "status"
    t.string   "hash_id"
    t.integer  "completed_entry_id"
    t.date     "completed_on"
    t.datetime "archived_at"
    t.string   "created_by"
    t.integer  "sort"
    t.boolean  "tip",                default: false
  end

  add_index "entries", ["archived_at"], name: "index_entries_on_archived_at", using: :btree
  add_index "entries", ["completed_entry_id"], name: "index_entries_on_completed_entry_id", using: :btree
  add_index "entries", ["completed_on"], name: "index_entries_on_completed_on", using: :btree
  add_index "entries", ["hash_id"], name: "index_entries_on_hash_id", unique: true, using: :btree
  add_index "entries", ["occurred_on"], name: "index_entries_on_occurred_on", using: :btree
  add_index "entries", ["status"], name: "index_entries_on_status", using: :btree
  add_index "entries", ["team_id"], name: "index_entries_on_team_id", using: :btree
  add_index "entries", ["user_id"], name: "index_entries_on_user_id", using: :btree

  create_table "entry_tags", force: :cascade do |t|
    t.integer  "entry_id"
    t.integer  "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hooks", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "team_id"
    t.text     "target_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "hooks", ["team_id"], name: "index_hooks_on_team_id", using: :btree
  add_index "hooks", ["user_id"], name: "index_hooks_on_user_id", using: :btree

  create_table "integration_links", force: :cascade do |t|
    t.integer  "team_id"
    t.string   "integration_type"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "integration_user_id"
    t.text     "meta_data"
    t.string   "token"
  end

  add_index "integration_links", ["integration_user_id"], name: "index_integration_links_on_integration_user_id", using: :btree

  create_table "integration_users", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "integration_type"
    t.string   "oauth_uid"
    t.string   "oauth_email"
    t.string   "oauth_access_token"
    t.boolean  "oauth_access_token_expires"
    t.datetime "oauth_access_token_expires_at"
    t.string   "oauth_refresh_token"
    t.text     "meta_data"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "integration_users", ["user_id"], name: "index_integration_users_on_user_id", using: :btree

  create_table "intercom_queues", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "processed_at"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "intercom_queues", ["user_id"], name: "index_intercom_queues_on_user_id", unique: true, using: :btree

  create_table "invitations", force: :cascade do |t|
    t.integer  "organization_id"
    t.text     "email_address"
    t.text     "full_name"
    t.text     "invitation_code"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.datetime "sent_at"
    t.datetime "redeemed_at"
    t.integer  "team_ids",        default: [],              array: true
    t.integer  "sender_id"
    t.datetime "declined_at"
  end

  add_index "invitations", ["declined_at"], name: "index_invitations_on_declined_at", using: :btree
  add_index "invitations", ["email_address"], name: "index_invitations_on_email_address", using: :btree
  add_index "invitations", ["invitation_code"], name: "index_invitations_on_invitation_code", using: :btree
  add_index "invitations", ["organization_id"], name: "index_invitations_on_organization_id", using: :btree
  add_index "invitations", ["sender_id"], name: "index_invitations_on_sender_id", using: :btree

  create_table "mentions", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "mentionable_id"
    t.string   "mentionable_type"
  end

  add_index "mentions", ["mentionable_type", "mentionable_id"], name: "index_mentions_on_mentionable_type_and_mentionable_id", using: :btree

  create_table "notifications", force: :cascade do |t|
    t.string   "for_notificable", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "entry_id",        null: false
    t.integer  "user_id",         null: false
    t.integer  "author_id",       null: false
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", null: false
    t.integer  "application_id",    null: false
    t.string   "token",             null: false
    t.integer  "expires_in",        null: false
    t.text     "redirect_uri",      null: false
    t.datetime "created_at",        null: false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id"
    t.string   "token",             null: false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        null: false
    t.string   "scopes"
  end

  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",                      null: false
    t.string   "uid",                       null: false
    t.string   "secret",                    null: false
    t.text     "redirect_uri",              null: false
    t.string   "scopes",       default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

  create_table "organization_memberships", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "organization_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "role",            default: "member"
    t.datetime "deleted_at"
    t.datetime "removed_at"
  end

  add_index "organization_memberships", ["deleted_at"], name: "index_organization_memberships_on_deleted_at", using: :btree
  add_index "organization_memberships", ["organization_id"], name: "index_organization_memberships_on_organization_id", using: :btree
  add_index "organization_memberships", ["removed_at"], name: "index_organization_memberships_on_removed_at", using: :btree
  add_index "organization_memberships", ["role"], name: "index_organization_memberships_on_role", using: :btree
  add_index "organization_memberships", ["user_id"], name: "index_organization_memberships_on_user_id", using: :btree

  create_table "organizations", force: :cascade do |t|
    t.text     "name"
    t.string   "slug"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "stripe_customer_token"
    t.datetime "trial_ends_at"
    t.string   "saml_meta_url"
    t.string   "hash_id"
    t.string   "logo"
    t.string   "profile_color"
    t.text     "plan_level"
    t.text     "plan_interval"
    t.text     "billing_name"
    t.boolean  "billed_manually",            default: false
    t.text     "autojoin_domain"
    t.text     "billing_email_address"
    t.string   "stripe_subscription_status"
  end

  add_index "organizations", ["autojoin_domain"], name: "index_organizations_on_autojoin_domain", unique: true, using: :btree
  add_index "organizations", ["hash_id"], name: "index_organizations_on_hash_id", unique: true, using: :btree
  add_index "organizations", ["plan_interval"], name: "index_organizations_on_plan_interval", using: :btree
  add_index "organizations", ["plan_level"], name: "index_organizations_on_plan_level", using: :btree
  add_index "organizations", ["slug"], name: "index_organizations_on_slug", using: :btree

  create_table "reaction_tags", force: :cascade do |t|
    t.integer  "reaction_id"
    t.integer  "tag_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "reactions", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "body"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "reaction_type"
    t.integer  "reactable_id"
    t.string   "reactable_type"
  end

  add_index "reactions", ["reactable_id", "reactable_type"], name: "index_reactions_on_reactable_id_and_reactable_type", using: :btree
  add_index "reactions", ["reaction_type"], name: "index_reactions_on_reaction_type", using: :btree
  add_index "reactions", ["user_id"], name: "index_reactions_on_user_id", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "team_memberships", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "team_id"
    t.datetime "created_at",                                                             null: false
    t.datetime "updated_at",                                                             null: false
    t.boolean  "reminder_monday",                       default: true
    t.boolean  "reminder_tuesday",                      default: true
    t.boolean  "reminder_wednesday",                    default: true
    t.boolean  "reminder_thursday",                     default: true
    t.boolean  "reminder_friday",                       default: true
    t.boolean  "reminder_saturday",                     default: false
    t.boolean  "reminder_sunday",                       default: false
    t.integer  "email_digest_seconds_since_midnight",   default: 30600
    t.integer  "email_reminder_seconds_since_midnight", default: 61200
    t.datetime "email_digest_last_sent_at"
    t.datetime "email_reminder_last_sent_at"
    t.string   "digest_status"
    t.string   "reminder_status"
    t.string   "subscribed_notifications",              default: ["comment", "mention"],              array: true
    t.datetime "deleted_at"
    t.datetime "removed_at"
    t.boolean  "digest_monday",                         default: true
    t.boolean  "digest_tuesday",                        default: true
    t.boolean  "digest_wednesday",                      default: true
    t.boolean  "digest_thursday",                       default: true
    t.boolean  "digest_friday",                         default: true
    t.boolean  "digest_saturday",                       default: false
    t.boolean  "digest_sunday",                         default: false
    t.datetime "next_reminder_time"
    t.datetime "next_digest_time"
    t.integer  "frozen_reminder_days",                  default: 0,                      null: false
    t.integer  "frozen_digest_days",                    default: 0,                      null: false
    t.boolean  "assign_task_reminder_status",           default: true,                   null: false
    t.boolean  "is_email_send_active",                  default: false,                  null: false
  end

  add_index "team_memberships", ["deleted_at"], name: "index_team_memberships_on_deleted_at", using: :btree
  add_index "team_memberships", ["next_digest_time"], name: "index_team_memberships_on_next_digest_time", using: :btree
  add_index "team_memberships", ["next_reminder_time"], name: "index_team_memberships_on_next_reminder_time", using: :btree
  add_index "team_memberships", ["removed_at"], name: "index_team_memberships_on_removed_at", using: :btree
  add_index "team_memberships", ["subscribed_notifications"], name: "index_team_memberships_on_subscribed_notifications", using: :btree
  add_index "team_memberships", ["team_id"], name: "index_team_memberships_on_team_id", using: :btree
  add_index "team_memberships", ["user_id"], name: "index_team_memberships_on_user_id", using: :btree

  create_table "teams", force: :cascade do |t|
    t.text     "name"
    t.datetime "created_at",                                                                null: false
    t.datetime "updated_at",                                                                null: false
    t.string   "slug"
    t.integer  "organization_id"
    t.text     "prompt_done",                   default: "What did you get done?"
    t.text     "prompt_goal",                   default: "What do you plan to get done?"
    t.text     "prompt_blocked",                default: "What is impeding your progress?"
    t.boolean  "public",                        default: true
    t.string   "hash_id"
    t.boolean  "enable_expandable_entries_box", default: false,                             null: false
    t.boolean  "enable_entry_timestamps"
    t.boolean  "carry_over_goals",              default: true,                              null: false
    t.integer  "owner_id"
  end

  add_index "teams", ["hash_id"], name: "index_teams_on_hash_id", unique: true, using: :btree
  add_index "teams", ["organization_id"], name: "index_teams_on_organization_id", using: :btree
  add_index "teams", ["public"], name: "index_teams_on_public", using: :btree
  add_index "teams", ["slug"], name: "index_teams_on_slug", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email_address",                                                          null: false
    t.string   "crypted_password"
    t.string   "salt"
    t.text     "full_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "api_token"
    t.string   "profile_color"
    t.datetime "deleted_at"
    t.string   "nickname"
    t.text     "sorting_name"
    t.string   "time_zone",                       default: "Pacific Time (US & Canada)"
    t.string   "portrait"
    t.string   "hash_id"
    t.integer  "personal_team_id"
    t.boolean  "show_personal_team",              default: true
    t.integer  "default_team_id"
    t.datetime "last_seen_at"
    t.text     "go_by_name"
    t.integer  "entries_count",                   default: 0,                            null: false
    t.datetime "onboarded_at"
    t.datetime "migrated_from_legacy_at"
    t.text     "reset_password_token"
    t.datetime "reset_password_email_sent_at"
    t.datetime "reset_password_token_expires_at"
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.datetime "verified_at"
    t.string   "verification_token"
    t.datetime "verification_token_expires_at"
    t.text     "autojoin_domain"
    t.string   "phone_number"
    t.integer  "orgid"
    t.string   "orgstatus"
  end

  add_index "users", ["autojoin_domain"], name: "index_users_on_autojoin_domain", using: :btree
  add_index "users", ["deleted_at"], name: "index_users_on_deleted_at", using: :btree
  add_index "users", ["email_address"], name: "index_users_on_email_address", unique: true, using: :btree
  add_index "users", ["go_by_name"], name: "index_users_on_go_by_name", using: :btree
  add_index "users", ["hash_id"], name: "index_users_on_hash_id", unique: true, using: :btree
  add_index "users", ["last_seen_at"], name: "index_users_on_last_seen_at", using: :btree
  add_index "users", ["migrated_from_legacy_at"], name: "index_users_on_migrated_from_legacy_at", using: :btree
  add_index "users", ["onboarded_at"], name: "index_users_on_onboarded_at", using: :btree
  add_index "users", ["personal_team_id"], name: "index_users_on_personal_team_id", unique: true, using: :btree
  add_index "users", ["remember_me_token"], name: "index_users_on_remember_me_token", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["show_personal_team"], name: "index_users_on_show_personal_team", using: :btree
  add_index "users", ["sorting_name"], name: "index_users_on_sorting_name", using: :btree
  add_index "users", ["verification_token"], name: "index_users_on_verification_token", using: :btree
  add_index "users", ["verified_at"], name: "index_users_on_verified_at", using: :btree

  add_foreign_key "alternate_emails", "users"
  add_foreign_key "hooks", "teams"
  add_foreign_key "hooks", "users"
  add_foreign_key "integration_users", "users"
  add_foreign_key "intercom_queues", "users"
end
